#!/usr/bin/env ruby

require 'json'
require 'paint'
require 'word_wrap'
require 'word_wrap/core_ext'

failed_only = false
quiet = false

while flag = ARGV.shift
  case flag
  when '-f', '--failed'
    failed_only = true
  when '-q', '--quiet'
    quiet = true
  when '-h', '--help'
    puts <<-EOH
Usage: pretty.rb [OPTIONS]
Options:
  -f, --failed    Only show failed controls
  -q, --quiet     Only show minimal information
  -h, --help      Print this message
    EOH
    exit
  end
end

content = STDIN.read

output = JSON.parse(content)

def tabbed_text(text)
  text.gsub("\n", "\n      ")
end

def clean_up_message(result)
  # return if result.nil?
  # puts result
  output = case result['status']
           when 'skipped'
             result['skip_message']
           when 'failed'
             "#{result['code_desc']}\n#{result['message'].chomp}\n"
           else
             result['code_desc']
           end

  tabbed_text(output)[0..700]
end

FAILED = '#FF3333'.freeze
PASSED = '#32CD32'.freeze
SKIPPED = '#BEBEBE'.freeze

output['profiles'].each do |profile|
  puts "\n" + profile['title']

  profile['controls'].each do |control|
    result_messages = []
    control_badge = '✓'
    control_color = PASSED
    control['results'].each do |result|
      next if failed_only && result['status'] != 'failed'

      case result['status']
      when 'passed'
        if control_color != FAILED
          color = PASSED
          badge = '✓'
        end
      when 'skipped'
        if control_color != FAILED
          control_color = color = SKIPPED
          control_badge = badge = '↺'
        end
      when 'failed'
        control_color = color = FAILED
        control_badge = badge = '×'
      end

      result_messages << Paint["    #{badge} #{clean_up_message(result)}", color]
    end

    next if result_messages.empty?
    puts Paint["  #{control_badge} #{control['id']}: #{control['title']}", control_color]
    if control['desc'] && control_color == FAILED
      puts Paint["    ⓘ #{tabbed_text(control['desc'].gsub("\n", ' ').fit(100))}\n", '#FF8C00']
    end
    puts result_messages if !quiet && control.has_key?('desc')
    # puts result_messages.inspect
  end
end
