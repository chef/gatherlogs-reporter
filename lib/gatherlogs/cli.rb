require 'json'
require 'clamp'
require 'fileutils'
require 'logger'

require "gatherlogs"
require "gatherlogs/shellout"

PROFILES_PATH = File.realpath(File.join(File.dirname(__FILE__), '../../profiles')).freeze
Clamp.allow_options_after_parameters = true

module Gatherlogs
  class CLI < Clamp::Command
    include Gatherlogs::Output
    include Gatherlogs::Shellout

    attr_accessor :current_log_path, :remote_cache_dir
    attr_accessor :profiles

    option ['-p', '--path'], 'PATH', 'Path to the gatherlogs for inspection', default: '.', attribute_name: :log_path
    option ['-r', '--remote'], 'REMOTE_URL', 'URL to the remote tar bal for inspection', attribute_name: :remote_url
    option ['-d', '--debug'], :flag, 'Enable debug output'
    option ['-s', '--system-only'], :flag, 'Only show system report', attribute_name: :summary_only
    option ['--profiles'], :flag, 'Show available profiles', attribute_name: :list_profiles
    option ['-v', '--verbose'], :flag, 'Show inspec test output'
    option ['-a', '--all'], :flag, 'Show all tests, default is to only show failed tests'
    option ['-q', '--quiet'], :flag, 'Only show the report output'
    option ['-m', '--monochrome'], :flag, "Don't use terminal colors for output"
    option ['--version'], :flag, 'Show current version'

    parameter "[PROFILE]", "profile to execute", attribute_name: :inspec_profile

    def initialize(*args)
      super
      enable_colors
      @profiles = nil
      @current_log_path = nil
      @remote_cache_dir = nil
    end

    def show_versions
      puts Gatherlogs::Version.cli_version
      puts Gatherlogs::Version.inspec_version
    end

    def reporter
      @reporter ||= Gatherlogs::Reporter.new({
        show_all_controls: all?,
        show_all_tests: verbose?
      })
    end

    def execute()
      parse_args

      return show_versions if version?
      return show_profiles if list_profiles?
      generate_report
    end

    def generate_report
      product = inspec_profile.dup

      output = log_working_dir do |log_path|
        product ||= detect_product(log_path)

        if product.nil?
          signal_usage_error 'Could not determine the product from gatherlog bundle, please specify a profile to use'
        end

        reporter.report(inspec_exec(product))
      end

      print_report('System report', output[:system_info])
      if output[:system_info].nil? && summary_only?
        error_msg "No system summary generated, #{product} not yet supported?"
      end
      print_report('Inspec report', output[:report]) unless summary_only?
    end

    def detect_product(log_path)
      debug "Attempting to detect gatherlogs product..."
      product = Gatherlogs::Product.detect(log_path)
      debug product.nil? ? 'Could not detect product' : "Detected '#{product}' files"

      product
    end

    def show_profiles
      puts profiles.sort.join("\n")
      exit
    end

    def profiles
      if @profiles.nil?
        possible_profiles = Dir.glob(File.join(PROFILES_PATH, '*/inspec.yml'))
        @profiles = possible_profiles.map { |p| File.basename(File.dirname(p)) }
        @profiles.reject! { |p| p == 'common' || p == 'glresources' }
      end
      @profiles
    end

    def print_report(title, report)
      return if report.empty?

      # this puts intentionally left blank
      puts ""
      puts title
      if report.is_a?(Hash)
        max_label_length = report.keys.map(&:length).max
        max_value_length = report.values.map{|v| v.to_s.length }.max
        puts '-' * (max_label_length+max_value_length+1)
        report.each do |k,v|
          puts "%#{max_label_length}s: %s" % [k,v.to_s.strip.chomp]
        end
        puts '-' * (max_label_length+max_value_length+1)
      else
        puts '-' * 80
        puts report.join("\n")
      end
    end

    def log_working_dir(&block)
      current_log_path = remote_url.nil? ? log_path.dup : fetch_remote_tar(remote_url)

      debug("Using log_path: #{current_log_path}")

      Dir.chdir(current_log_path) do
        return yield '.'
      end
    ensure
      FileUtils.remove_entry remote_cache_dir if remote_cache_dir && File.exists?(remote_cache_dir)
    end

    def fetch_remote_tar(url)
      info "Fetching remote gatherlogs bundle"
      @remote_cache_dir = Dir.mktmpdir('gatherlogs')
      debug "Remote cache dir: #{@remote_cache_dir}"

      extension = remote_url.split('.').last
      local_filename = File.join(remote_cache_dir, "gatherlogs.#{extension}")

      cmd = ['wget', remote_url, '-O', local_filename]
      shellout!(cmd)

      cmd = ['tar', 'xvf', local_filename, '-C', remote_cache_dir, '--strip-components', '2']
      shellout!(cmd)

      remote_cache_dir
    end

    def find_profile_path(profile)
      path = File.join(::PROFILES_PATH, profile)
      if File.exists?(path)
        return path
      else
        raise "Couldn't find '#{profile}' profile, tried in '#{path}'"
      end
    end

    def parse_args
      if debug?
        Gatherlogs.logger.level = ::Logger::DEBUG
      elsif quiet?
        Gatherlogs.logger.level = ::Logger::ERROR
      else
        Gatherlogs.logger.level = ::Logger::INFO
        Gatherlogs.logger.formatter = proc { |severity, datetime, progname, msg| "#{msg}\n" }
      end

      if monochrome?
        disable_colors
      end

    end

    def inspec_exec(product)
      profile = find_profile_path(product)

      cmd = ['inspec', 'exec', profile, '--reporter', 'json']

      info "Running inspec profile for #{product}..."

      inspec = shellout!(cmd, { returns: [0, 100, 101] })
      JSON.parse(inspec.stdout)
    end
  end
end
