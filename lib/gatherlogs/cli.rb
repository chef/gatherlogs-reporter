require 'json'
require 'clamp'
require 'fileutils'
require 'logger'
require 'tempfile'

require 'gatherlogs'
require 'gatherlogs/shellout'

PROFILES_PATH = File.expand_path('../../profiles', __dir__).freeze
Clamp.allow_options_after_parameters = true

module Gatherlogs
  class CLI < Clamp::Command
    include Gatherlogs::Output
    include Gatherlogs::Shellout

    attr_accessor :current_log_path, :tmp_cache_file
    attr_writer :profiles

    option ['-p', '--path'], 'PATH', 'Path to the gatherlogs for inspection',
           default: '.', attribute_name: :log_path
    option ['-r', '--remote'], 'REMOTE_URL',
           'URL to the remote tar bal for inspection',
           attribute_name: :remote_url
    option ['-d', '--debug'], :flag, 'Enable debug output'
    option ['-s', '--system-only'], :flag, 'Only show system report',
           attribute_name: :summary_only
    option ['--profiles'], :flag, 'Show available profiles',
           attribute_name: :list_profiles
    option ['-v', '--verbose'], :flag, 'Show inspec test output'
    option ['-a', '--all'], :flag,
           'Show all tests, default is to only show failed tests'
    option ['-q', '--quiet'], :flag, 'Only show the report output'
    option ['-m', '--monochrome'], :flag, "Don't use terminal colors for output"
    option ['--version'], :flag, 'Show current version'

    parameter '[PROFILE]', 'profile to execute', attribute_name: :inspec_profile

    def initialize(*args)
      super
      enable_colors
      @profiles = nil
      @current_log_path = nil
      @tmp_cache_file = nil
    end

    def show_versions
      puts Gatherlogs::Version.cli_version
      puts Gatherlogs::Version.inspec_version
    end

    def reporter
      @reporter ||= Gatherlogs::Reporter.new(
        show_all_controls: all?,
        show_all_tests: verbose?
      )
    end

    def execute
      parse_args

      return show_versions if version?
      return show_profiles if list_profiles?

      generate_report
    end

    def generate_report
      product = inspec_profile.dup

      output = log_working_dir do |log_path|
        product ||= detect_product(log_path)
        reporter.report(inspec_exec(log_path, product))
      end

      print_report('System report', output[:system_info])
      if output[:system_info].nil? && summary_only?
        error_msg "No system summary generated, #{product} not yet supported?"
      end
      print_report('Inspec report', output[:report]) unless summary_only?
    end

    def detect_product(log_path)
      debug 'Attempting to detect gatherlogs product...'
      Gatherlogs::Product.detect(log_path)
    end

    def show_profiles
      puts profiles.sort.join("\n")
    end

    def profiles
      if @profiles.nil?
        possible_profiles = Dir.glob(File.join(PROFILES_PATH, '*/inspec.yml'))
        @profiles = possible_profiles.map { |p| File.basename(File.dirname(p)) }
      end
      @profiles.reject! { |p| %w[common glresources].include?(p) }
      @profiles
    end

    def print_report(title, report)
      return if report.empty?

      # this puts intentionally left blank
      puts ''
      puts title
      if report.is_a?(Hash)
        print_hash_report(report)
      else
        print_array_report(report)
      end
    end

    def print_hash_report(report)
      max_label_length = report.keys.map(&:length).max
      max_value_length = report.values.map { |v| v.to_s.length }.max
      puts '-' * (max_label_length + max_value_length + 2)
      report.each do |k, v|
        puts format("%#{max_label_length}s: %s", k, v.to_s.strip.chomp)
      end
      puts '-' * (max_label_length + max_value_length + 2)
    end

    def print_array_report(report)
      puts '-' * 80
      puts report.join("\n")
    end

    def log_working_dir
      current_log_path = if remote_url.nil?
                           log_path.dup
                         else
                           fetch_remote_tar(remote_url)
                         end

      if File.directory?(current_log_path)
        debug("Using log_path: #{current_log_path}")
        return yield current_log_path
      else
        Dir.mktmpdir do |work_dir|
          extract_bundle(current_log_path, work_dir)
          return yield work_dir
        end
      end
    ensure
      tmp_cache_file&.unlink
    end

    def extract_bundle(filename, path)
      cmd = [
        'tar', 'xvf', filename, '-C', path,
        '--strip-components', '2'
      ]
      shellout!(cmd)
    end

    def fetch_remote_tar(url)
      return if url.nil?

      info 'Fetching remote gatherlogs bundle'
      @tmp_cache_file = ::Tempfile.new('gatherlogs')
      @tmp_cache_file.close
      debug "tmp_cache_file: #{@tmp_cache_file}"

      shellout!(['wget', url, '-O', @tmp_cache_file.path])

      @tmp_cache_file.path
    end

    def find_profile_path(profile)
      path = File.join(::PROFILES_PATH, profile)
      return path if File.exist?(path)

      raise "Couldn't find '#{profile}' profile, tried in '#{path}'"
    end

    def parse_args
      if debug?
        Gatherlogs.logger.level = ::Logger::DEBUG
      elsif quiet?
        Gatherlogs.logger.level = ::Logger::ERROR
      else
        Gatherlogs.logger.level = ::Logger::INFO
        Gatherlogs.logger.formatter = proc { |_sev, _datetime, _name, msg|
          "#{msg}\n"
        }
      end

      disable_colors if monochrome?
    end

    def inspec_exec(path, product)
      signal_usage_error 'Please specify a profile to use' if product.nil?
      info "Running inspec profile for #{product}..."

      profile = find_profile_path(product)

      cmd = [
        'inspec', 'exec', profile, '--no-create-lockfile', '--reporter', 'json'
      ]
      Dir.chdir(path) do
        inspec = shellout!(cmd, returns: [0, 100, 101])
        debug inspec.stderr unless inspec.stderr.empty?
        JSON.parse(inspec.stdout)
      end
    end
  end
end
