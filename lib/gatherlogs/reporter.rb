require 'gatherlogs/output'
require 'gatherlogs/control_report'
require 'logger'

module Gatherlogs
  class Reporter
    include Gatherlogs::Output

    attr_reader :show_all_controls, :show_all_tests

    def initialize(args)
      debug args.inspect
      @options = args
    end

    def min_impact
      @options[:min_impact].to_f || 0.0
    end

    def show_all_tests
      @options[:show_all_tests] || false
    end

    def show_all_controls
      @options[:show_all_controls] || false
    end

    def process_profile(profile)
      control_report = Gatherlogs::ControlReport.new(
        profile['controls'],
        @options
      )
      
      {
        system_info: control_report.system_info,
        report: control_report.report
      }
    end

    def report(json)
      output = { system_info: {}, report: [] }

      json['profiles'].each do |profile|
        debug profile['title']
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
