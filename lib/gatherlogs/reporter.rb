require 'gatherlogs/output'
require 'gatherlogs/control_report'
require 'logger'

module Gatherlogs
  class Reporter
    include Gatherlogs::Output

    attr_reader :show_all_controls, :show_all_tests

    def initialize(args)
      @show_all_controls = args[:show_all_controls]
      @show_all_tests = args[:show_all_tests]
    end

    def process_profile(profile)
      control_report = Gatherlogs::ControlReport.new(profile['controls'], show_all_controls, show_all_tests)
      {
        system_info: control_report.system_info,
        report: control_report.report 
      }
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
