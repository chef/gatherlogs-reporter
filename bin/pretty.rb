#!/usr/bin/env ruby

require 'json'
require 'paint'
require 'word_wrap'
require 'word_wrap/core_ext'

FAILED = '#FF3333'.freeze
PASSED = '#32CD32'.freeze
SKIPPED = '#BEBEBE'.freeze
INFO = '#FF8C00'.freeze


class GatherlogsInspecReporter
  attr_reader :log_level, :all_controls, :verbose

  def initialize
    @all_controls = false
    @verbose = false
    @log_level = :info

    parse_args
  end

  def parse_args
    while flag = ARGV.shift
      case flag
      when '-d', '--debug'
        @log_level = :debug
      when '-a', '--all'
        @all_controls = true
      when '-v', '--verbose'
        @verbose = true
      end
    end
  end

  def debug(msg)
    return unless log_level == :debug
    STDERR.puts("[DEBUG] #{msg}")
  end

  # Make sure that we tab over the output for multiline text so that it lines
  # up with the rest of the output.
  def tabbed_text(text, spaces = 0)
    Array(text).join("\n").gsub("\n", "\n#{' ' * (6 + spaces.to_i)}")
  end

  # Format the desc text in the control
  # Control snippet:
  #    desc "This is a description from the control!"
  def desc_text(control)
    text = Array(control['desc'])
    return if text.empty?

    labeled_output '⇨', tabbed_text(text) + "\n"
  end

  # Format output for kb tagged text in the control\
  # Control snippet:
  #    tag kb: "http://test.com"
  def kb_text(control)
    text = Array(control['tags']['kb'])
    return if text.empty?

    labeled_output 'KB', tabbed_text(text, 2)
  end

  # Format output for summary tagged text in the control
  # Control snippet:
  #    tag summary: "Some output in the control"
  def summary_text(control)
    text = control['tags']['summary']
    return if text.nil?

    labeled_output '🛈', tabbed_text(text) + "\n"
  end

  def labeled_output(label, output, override_colors = {})
    colors = { label: INFO, output: :nothing }.merge(override_colors)
    Paint%[
      "%{label_output} #{output}",
      colors[:output],
      label_output: [label, colors[:label]]
    ]
  end

  # Print out detailed info for each test subsection
  # For example the description, summary or kb info provided in the control
  def subsection(output)
    puts '    ' + output unless output.nil? || output.empty?
  end

  # Format the output used for showing the control test results
  def format_result_message(badge, result, color)
    output = case result['status']
             when 'skipped'
               result['skip_message']
             when 'failed'
               "#{result['code_desc']}\n#{result['message'].chomp}\n"
             else
               result['code_desc']
             end

    Paint["    #{tabbed_text("#{badge} #{output}")[0..700]}", color]
  end

  # Format the output for showing the control title
  def control_info(badge, info, color)
    Paint["  #{badge} #{info}", color]
  end

  def report(json)
    json['profiles'].each do |profile|
      # don't show profiles that have no controls
      next if profile['controls'].empty?

      puts "\n" + profile['title']

      profile['controls'].each do |control|
        debug control
        
        control_badge = '✓'
        control_status = PASSED
        result_messages = []

        control['results'].each do |result|
          case result['status']
          when 'passed'
            test_status = PASSED
            test_badge = '✓'
          when 'skipped'
            if control_status != FAILED
              control_status = test_status = SKIPPED
              control_badge = test_badge = '↺'
            end
          when 'failed'
            control_status = test_status = FAILED
            control_badge = test_badge = '✗'
          end

          result_messages << format_result_message(test_badge, result, test_status) if verbose
        end

        next if !all_controls && control_status == PASSED

        puts control_info(control_badge, "#{control['id']}: #{control['title']}", control_status)
        if control_status == FAILED
          subsection desc_text(control)
          subsection summary_text(control)
          subsection kb_text(control)
        end
        puts result_messages if verbose
      end
    end
  end
end

begin
  puts "Generating report..."
  reporter = GatherlogsInspecReporter.new()
  reporter.report(JSON.parse(STDIN.read))
rescue => e
  puts "[ERROR] #{e}"
  puts "Backtrace:"
  puts e.backtrace
  exit 1
end
