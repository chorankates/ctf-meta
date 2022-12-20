#!/bin/env ruby
## write_htb_markdown

require 'erb'
require 'optparse'
require 'pry'

# TODO don't require a static github user
# TODO figure out pathing garbage, we actually want this at the top level

HTB_MACHINES = "
# ctf-meta
individual repos for CTF/HTB writeups

## HTB machines

| name | completed? | last modified |
|------|------------|---------------|
<% for m in @machines.keys %>
| [<%= m %>](https://github.com/chorankates/<%= m %>) | <%= @machines[m][:completed] %> | <%= @machines[m][:modified] %> |<% end %>

"


TEMPLATES = {
  :htb => HTB_MACHINES
}

def get_machines()
  machines = Hash.new
  paths = Dir.glob('*').sort
  paths.each do |p|
    name = $1 if p.match(/\d+\-(\w*)/)
    next if name.nil? # relative paths - but TODO at least log this
    completed = File.file?(sprintf('%s/.completed', p))
    modified  = File.stat(sprintf('%s/README.md', p)).mtime.strftime('%Y/%m/%d @ %H:%M') # TODO this is riskier than it should be
    machines[name] = {
      :completed => completed ? ':heavy_check_mark:' : '',
      :modified  => modified,
    }
  end

  machines
end

def render_template(type)
  template = TEMPLATES[type]
  renderer = ERB.new(template)

  renderer.result()
end

def parse_options
  # setting some defaults
  options = {
    :mode       => :htb,
  }

  parser = OptionParser.new do |o|

    o.on('-m', '--mode <mode>', "mode of execution, individual or overall") do |p|
      options[:mode] = p.to_sym
    end

  end

  parser.parse!

  options
end


context  = Hash.new
required = Array.new

options = parse_options

if options[:mode].eql?(:htb)
  required = [ :machines ]
  @machines = get_machines()
  options[:output] = './README.md.gen'

else
  puts sprintf("invalid mode[%s] specified", options[:mode])
  exit 1
end

required.each do |r|
  # this is so gross, there has to be a better way to do it
  rr = sprintf('@%s', r).to_sym

  if instance_variable_get(rr).nil?
    print sprintf('unspecified[%s], specify value: ', rr)
    response = gets().chomp!.gsub(' ', '_')

    if r.eql?(:number)
      response = sprintf('%02i', response)
    elsif r.eql?(:categories)
      response = response.split(',')
    end

    instance_variable_set(rr, response)
  end

end

r = render_template(options[:mode])

# don't want to accidentally overrwrite something, particularly if the changes are unstaged
if File.file?(options[:output])
  puts sprintf('file[%s] already exists, will not overrwrite', File.expand_path(options[:output]))
  exit(1)
end

bytes = File.open(options[:output], 'w') do |f|
  f.write(r)
end

puts sprintf('wrote[%s] to[%s]', bytes, options[:output])

