require 'gatherlogs/output'
require 'logger'

module Gatherlogs
  class Reporter
    include Gatherlogs::Output

    attr_reader :show_all_controls, :show_all_tests

    def initialize(args)
      @show_all_controls = args[:show_all_controls]
      @show_all_tests = args[:show_all_tests]
      @logger = args[:logger] || Logger.new(STDERR)

      enable_colors
    end

    # Format the desc text in the control
    # Control snippet:
    #    desc "This is a description from the control!"
    def desc_text(control)
      return unless control.has_key?('desc')

      text = control['desc']
      return if text.empty?

      labeled_output DESC_ICON, tabbed_text(text) + "\n"
    end

    # Format output for kb tagged text in the control\
    # Control snippet:
    #    tag kb: "http://test.com"
    def kb_text(control)
      text = Array(control['tags']['kb'])
      return if text.empty?

      labeled_output KB_ICON, tabbed_text(text) + "\n"
    end

    # Format output for summary tagged text in the control
    # Control snippet:
    #    tag summary: "Some output in the control"
    def summary_text(control)
      text = control['tags']['summary']
      return if text.nil?

      labeled_output SUMMARY_ICON, tabbed_text(text) + "\n"
    end

    # Format the output used for showing the control test results
    def format_result_message(result)
      output = case result['status']
               when 'skipped'
                 badge = SKIPPED_ICON
                 color = SKIPPED
                 result['skip_message']
               when 'failed'
                 badge = FAILED_ICON
                 color = FAILED
                 truncate "#{result['code_desc']}\n#{result['message'].chomp}"
               else
                 badge = PASSED_ICON
                 color = PASSED
                 result['code_desc']
               end

      message = tabbed_text "#{badge} #{output}"
      colorize "#{message}", color
    end

    # Format the output for showing the control title
    def control_info(badge, info, color)
      colorize "#{badge} #{info}", color
    end

    def process_profile(profile)
      output = { system_info: {}, report: [] }
      keys = profile['controls'].map.with_index { |c,index| [index,c['id']] }
      keys.sort { |a,b| a.last <=> b.last }.each do |index, id|
        control = profile['controls'][index]
        result_messages = []

        if control['tags'].include?('system')
          output[:system_info].merge!(control['tags']['system'])
        end

        verbose_tag = control['tags'].include?('verbose') ? control['tags']['verbose'] : false

        control_status = PASSED
        control_badge = PASSED_ICON

        control['results'].each do |result|
          case result['status']
          when 'skipped'
            if control_status != FAILED
              control_status = SKIPPED
              control_badge = SKIPPED_ICON
            end
          when 'failed'
            control_status = FAILED
            control_badge = FAILED_ICON
          end

          # If there is an source code error in our controls we should show that
          source_error = result['code_desc'].match?(/Control Source Code Error/)

          # gather up result messages for output later
          # show_all_tests can be set globally using -v on the cli or by adding
          # `tag verbose: true` to the control
          if show_all_tests || source_error || (verbose_tag && result['status'] == 'failed')
            result_messages << subsection(format_result_message(result))
          end
        end
        next unless show_all_controls || control_status == FAILED

        control_title = "#{control['id']}: #{control['title']}"
        output[:report] << control_info(control_badge, control_title, control_status)

        # generate useful output
        if control_status == FAILED
          output[:report] << subsection(desc_text(control))
          output[:report] << subsection(summary_text(control))
          output[:report] << subsection(kb_text(control))
        end

        unless result_messages.empty?
          output[:report] += result_messages
          output[:report] << "" # add blank line after messages
        end
      end

      # get rid of the nil items
      output[:report].compact!

      output
    end

    def report(json)
      output = { system_info: {}, report: [] }

      json['profiles'].each do |profile|
        # don't show profiles that have no controls
        next if profile['controls'].empty?
        result = process_profile(profile)
        # Need to merge all the profiles together

        output[:report] += result[:report]
        output[:system_info].merge!(result[:system_info])
      end

      output
    end
  end
end
