require 'gatherlogs/output'

module Gatherlogs
  class ControlReport
    include Gatherlogs::Output

    attr_accessor :controls, :system_info, :report, :verbose
    attr_accessor :show_all_tests

    def initialize(controls, show_all_controls, show_all_tests)
      @system_info = {}
      @controls = controls
      @show_all_controls = show_all_controls
      @show_all_tests = show_all_tests
      @report = process_ordered_controls
    end

    def process_ordered_controls
      all_reports = []
      ordered_control_ids.each do |index, id|
        debug "Processing control #{id}"
        control = controls[index]
        report = process_control(control)

        all_reports += report unless report.nil?
      end

      all_reports
    end

    def ordered_control_ids
      keys = controls.map.with_index { |c, index| [index, c['id']] }
      keys.sort_by(&:last)
    end

    def update_system_info(tags)
      return unless tags.include?('system')

      system_info.merge!(tags['system'])
    end

    def update_verbose_control(tags)
      return unless tags.include?('verbose')

      @verbose = tags['verbose']
    end

    # Format the desc text in the control
    # Control snippet:
    #    desc "This is a description from the control!"
    def desc_text(control)
      return unless control.key?('desc')

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

    def process_control(control)
      report = []
      @status = PASSED
      @badge = PASSED_ICON
      @verbose = false

      update_system_info(control['tags'])

      # included controls show up in the parent but with no results
      # so we need to skip them but make sure to grab sys info first
      return if control['results'].empty?

      update_verbose_control(control['tags'])

      result_messages = control['results'].map do |result|
        update_status(result['status'])
        format_result(result)
      end.compact

      # by default only show the failed controls
      return unless @show_all_controls || @status == FAILED

      report += control_summary(control)

      unless result_messages.empty?
        report += result_messages
        report << '' # add blank line after messages
      end
      report.compact
    end

    def control_summary(control)
      summary = []
      summary << control_title(control)
      if @status == FAILED
        summary << subsection(desc_text(control))
        summary << subsection(summary_text(control))
        summary << subsection(kb_text(control))
      end

      summary
    end

    def control_title(control)
      colorize "#{@badge} #{control['id']}: #{control['title']}", @status
    end

    def source_error?(result)
      result['status'] == 'failed' &&
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
                 truncate "#{result['code_desc']}\n#{result['message']}".chomp
               else
                 badge = PASSED_ICON
                 color = PASSED
                 result['code_desc']
               end
      message = tabbed_text "#{badge} #{output}"
      colorize message.to_s, color
    end

    def update_status(result_status)
      case result_status
      when 'skipped'
        if @status != FAILED
          @status = SKIPPED
          @badge = SKIPPED_ICON
        end
      when 'failed'
        @status = FAILED
        @badge = FAILED_ICON
      end
    end

    def format_result(result)
      return if !@show_all_tests && !source_error?(result) &&
                !(verbose && result['status'] == 'failed')

      subsection(format_result_message(result))
    end
  end
end
