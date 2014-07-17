#!/usr/bin/ruby
#
# E.g., run on foreman server with
#   clear-hostgroups.rb c1a2 c1a3.exampe.com
#
# Requires Foreman 1.6.0.15+

require 'rubygems'
require 'erb'
require 'foreman_api'
require 'logger'
require 'optparse'
require 'ostruct'
require 'set'
require 'yaml'

class Optparse
  def self.parse(args)
    options = OpenStruct.new
    options.base_url = 'https://127.0.0.1'
    options.password = 'changeme'
    options.username = 'admin'

    opt_parser = OptionParser.new do |opts|
      opts.banner = <<-EOS
Usage: #{__FILE__} [OPTIONS] COMMAND
  COMMAND
    clear_hostroup node1 node2.example.com
    set_hostgroup "my awesome hostgroup" node3 node4.example.com node5

  OPTIONS
      EOS

      opts.on('-b', '--url_base URL', 'Base URL') do |b|
        options.base_url = b
      end

      opts.on('-p', '--password NAME', 'password') do |p|
        options.password = p
      end

      opts.on('-u', '--username NAME', 'username') do |u|
        options.username = u
      end

      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end
    opt_parser.parse!(args)
    options
  end
end

def get_hostgroup_id(hostgroup_name='')
  puts  hostgroup_name
  all_hostgroups = @hostgroups.index()[0]['results']
  all_hostgroups.each do |hg|
    if hg['name'] == hostgroup_name
      return hg['id']
    end
  end
  #return hostgroup_name in case it was an id
  hostgroup_name
end

def set_hostgroup(hostgroup_id='')
  if hostgroup_id == ''
    hosts_to_clear = Set.new(ARGV[1..-1])
  else
    hosts_to_clear = Set.new(ARGV[2..-1])
  end

  all_hosts = @hosts.index()[0]['results']
  all_hosts.each do |h|
    longname = h['name']
    shortname = /^(.*?)\./.match(h['name'])[1]
    if hosts_to_clear.include?(longname) or hosts_to_clear.include?(shortname)
      h['hostgroup_id'] = ''
       data = { 'id' => h['id'],
         'host' => {
            'hostgroup_id'  => hostgroup_id,
            }
      }
      @hosts.update(data)
    end
  end
end


options = Optparse.parse(ARGV)

auth = {
  :base_url => options.base_url,
  :username => options.username,
  :password => options.password
}

@hosts  = ForemanApi::Resources::Host.new(auth)
@hostgroups  = ForemanApi::Resources::Hostgroup.new(auth)

case ARGV[0]

when 'clear_hostgroup'
  set_hostgroup
when 'set_hostgroup'
  set_hostgroup(get_hostgroup_id(ARGV[1]))
else
  puts Optparse.parse(['-h'])
end
