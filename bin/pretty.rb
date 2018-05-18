#!/usr/bin/env ruby

require 'json'
require 'paint'

failed_only = false
while flag = ARGV.shift
  case flag
  when '-f', '--failed'
    failed_only = true
  when '-h', '--help'
    puts <<-EOH
Usage: pretty.rb [OPTIONS]
Options:
  -f, --failed    Only show failed controls
  -h, --help      Print this message
    EOH
    exit
  end
end

content = STDIN.read

output = JSON.parse(content)

def clean_up_message(result)
  # return if result.nil?
  # puts result
  output = case result['status']
           when 'skipped'
             result['skip_message']
           when 'failed'
             # puts result
             "#{result['code_desc']}\n#{result['message'].chomp}\n"
           else
             result['code_desc']
           end

  output.gsub("\n", "\n      ")[0..200]
end

output['profiles'].each do |profile|
  puts "\n" + profile['title']
  profile['controls'].each do |control|
    result_messages = []
    control_badge = '✓'
    control_color = '#32CD32'
    control['results'].each do |result|
      next if failed_only && result['status'] != 'failed'

      case result['status']
      when 'passed'
        color = '#32CD32'
        badge = '✓'
        msg = 'message'
      when 'skipped'
        if control_color != :red
          control_color = color = '#BEBEBE'
          control_badge = badge = '↺'
        end
      when 'failed'
        control_color = color = '#FF3333'
        control_badge = badge = '×'
      end

      result_messages << Paint["    #{badge} #{clean_up_message(result)}", color]
    end

    next if result_messages.empty?

    puts Paint["  #{control_badge} #{control['id']}: #{control['title']}", control_color]
    puts result_messages
    # puts result_messages.inspect


  end
end
