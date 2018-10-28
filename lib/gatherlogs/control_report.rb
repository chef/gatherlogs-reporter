require 'gatherlogs/output'

module Gatherlogs
  class ControlReport
    include Gatherlogs::Output
    attr_accessor :controls, :system_info, :report, :verbose

    def initialize(controls, show_all_controls, show_all_tests)
      @system_info = {}
      @controls = controls
      @show_all_controls = show_all_controls
      @show_all_tests = show_all_tests
      @report = []

      process
    end

    def ordered_control_ids
      keys = controls.map.with_index { |c,index| [index,c['id']] }
      keys.sort { |a,b| a.last <=> b.last }
    end

    def update_system_info(tags)
      return unless tags.include?('system')
      system_info.merge!(tags['system'])
    end

    def set_verbose(tags)
      return unless tags.include?('verbose')
      @verbose = tags['verbose']
    end

    # Format the desc text in the control
    # Control snippet:
    #    desc "This is a description from the control!"
    def desc_text(control)
      return unless control.has_key?('desc')

      text = control['desc']
      return if text.nil? || text.empty?

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

    def process
      ordered_control_ids.each do |index,id|
        @status = PASSED
        @badge = PASSED_ICON
        @verbose = false

        control = controls[index]

        update_system_info(control['tags'])
        set_verbose(control['tags'])

        result_messages = control['results'].map{ |r| process_result(r) }.compact
        next unless @show_all_controls || @status == FAILED

        @report << control_title(control)
        if @status == FAILED
          @report << subsection(desc_text(control))
          @report << subsection(summary_text(control))
          @report << subsection(kb_text(control))
        end

        unless result_messages.empty?
          @report += result_messages
          @report << "" # add blank line after messages
        end
      end
      @report.compact!
    end

    def control_title(control)
      colorize "#{@badge} #{control['id']}: #{control['title']}", @status
    end

    def source_error?(result)
      result['code_desc'].match?(/Control Source Code Error/)
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
                 puts result
                 truncate "#{result['code_desc']}\n#{result['message']}".chomp
               else
                 badge = PASSED_ICON
                 color = PASSED
                 result['code_desc']
               end

      message = tabbed_text "#{badge} #{output}"
      colorize "#{message}", color
    end

    def process_result(result)
      case result['status']
      when 'skipped'
        if @status != FAILED
          @status = SKIPPED
          @badge = SKIPPED_ICON
        end
      when 'failed'
        @status = FAILED
        @badge = FAILED_ICON
      end

      if @show_all_tests || source_error?(result) || (verbose && result['status'] = 'failed')
        subsection(format_result_message(result))
      end
    end
  end
end
