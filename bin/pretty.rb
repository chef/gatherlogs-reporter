#!/usr/bin/env ruby

require 'json'
require 'paint'
require 'word_wrap'
require 'word_wrap/core_ext'

FAILED = '#FF3333'.freeze
PASSED = '#32CD32'.freeze
SKIPPED = '#BEBEBE'.freeze

all_controls = false
verbose = false

while flag = ARGV.shift
  case flag
  when '-a', '--all'
    all_controls = true
  when '-v', '--verbose'
    verbose = true
  end
end

content = STDIN.read

begin
  output = JSON.parse(content)
rescue
  puts Paint["Error parsing json output from inspec", FAILED]
  puts content
  exit 1
end

def tabbed_text(text)
  text.gsub("\n", "\n      ")
end

def info_text(text)
  Paint["ⓘ #{tabbed_text(text)}\n", '#FF8C00']
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

output['profiles'].each do |profile|
  # don't show profiles that have no controls
  next if profile['controls'].empty?

  puts "\n" + profile['title']

  profile['controls'].each do |control|
    result_messages = []
    control_badge = '✓'
    control_color = PASSED
    control['results'].each do |result|
      next if !all_controls && result['status'] != 'failed'

      case result['status']
      when 'passed'
        color = PASSED
        badge = '✓'
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
      puts '    ' + info_text(control['desc'])
    end
    puts result_messages if verbose && control.has_key?('desc')
    # puts result_messages.inspect
  end
end
