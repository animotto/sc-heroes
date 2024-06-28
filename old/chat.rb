#!/usr/bin/env ruby

$:.unshift("#{__dir__}/lib")

require "optparse"
require "json"
require "readline"
require "sc-heroes"

options = {
  :config => "default",
}

begin
  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [-c config]"
    opts.on("-c config", "", "Load config") do |v|
      options[:config] = v
    end
  end.parse!
rescue
end

configFile = "#{__dir__}/#{options[:config]}.conf"
unless File.exist?(configFile)
  puts("Can't load configuration file #{options[:config]}")
  exit
end
config = JSON.parse(File.read(configFile))
config.transform_keys!(&:to_sym)

puts("Connecting to the chat server #{config[:address]}:#{config[:port]}")
chat = SCHeroes::Chat.new(config)

puts("Init with name #{config[:name]}")
chat.join(config)
chat.join_clan(config)

Thread.new do
  loop do
    chat.read do |message|
      print("\e[1G\e[0J")
      msg = "\e[37;44m\e[1msize: \e[22m%d \e[1mtimestamp: \e[22m%s \e[1muid: \e[22m%d \e[1mtitle: \e[22m%s\e[0m" % [
        message[:message_size],
        Time.at(message[:timestamp]).strftime("%d.%m.%Y %H:%M:%S"),
        message[:uid],
        config[:titles].key?(message[:title].to_s) ? config[:titles][message[:title].to_s] : message[:title],
      ]
      puts(msg)
      msg = "\e[35;1m%s\e[31;1m%s\e[35;1m: \e[%d;22m%s\e[0m" % [
        message[:name],
        (not message[:info].empty?) ? " #{message[:info]}" : "",
        message[:clan] ? 32 : 33,
        message[:message],
      ]
      puts(msg)      
      Readline.refresh_line
    end
  end
end

loop do
  line = Readline.readline("#{config[:name]}@#{config[:country]}> ", true)
  break unless line
  cmds = line.strip
  if cmds.empty?
    Readline::HISTORY.pop
    next
  end
  cmds = cmds.split(/\s+/)
  cmd = cmds[0].downcase
  unless cmd.start_with?("/")
    chat.say(line)
    next
  end

  cmd.delete_prefix!("/")
  case cmd
  when "quit", "q"
    exit
  when "change"
    country = cmds[1]
    if country.nil?
      puts("Specify country")
      next
    end
    config[:country] = country
    chat.change(config)
  else
    puts("Unrecognized command: #{cmd}")
  end
end
