require 'json'
require 'clamp'
require 'fileutils'
require 'logger'
require 'tempfile'
require 'inspec'

require 'gatherlogs'
require 'gatherlogs/shellout'

PROFILES_PATH = File.expand_path('../../profiles', __dir__).freeze
Clamp.allow_options_after_parameters = true

module Gatherlogs
  class CLI < Clamp::Command
    include Gatherlogs::Output
    include Gatherlogs::Shellout

    attr_accessor :current_log_path
    attr_writer :profiles

    option ['-p', '--path'], 'PATH',
           'Path to the gatherlogs directory or a compressed bundle',
           default: '.', attribute_name: :log_path
    option ['-r', '--remote'], 'REMOTE_URL',
           'URL to the remote bundle for inspection',
           attribute_name: :remote_url
    option ['-d', '--debug'], :flag, 'Enable debug output'
    option ['-s', '--system-only'], :flag, 'Only show system report',
           attribute_name: :summary_only
    option ['--profiles'], :flag, 'Show available profiles',
           attribute_name: :list_profiles
    option ['-v', '--verbose'], :flag, 'Show output from all control tests'
    option ['-a', '--all'], :flag,
           'Show all tests, default is to only show failed tests'
    option ['-i', '--impact'], 'IMPACT',
           'Only show tests that are higher than the given IMPACT value (0-1)',
           attribute_name: :min_impact

    option ['-q', '--quiet'], :flag, 'Only show the report output'
    option ['-m', '--monochrome'], :flag, "Don't use terminal colors for output"
    option ['--version'], :flag, 'Show current version'

    parameter '[PROFILE]', 'profile to execute', attribute_name: :inspec_profile

    def initialize(*args)
      super
      enable_colors
      @profiles = nil
      @current_log_path = nil
      @cleanup_paths = []
    end

    def show_versions
      puts Gatherlogs::Version.cli_version
      puts Gatherlogs::Version.inspec_version
    end

    def reporter
      @reporter ||= Gatherlogs::Reporter.new(
        show_all_controls: all?,
        show_all_tests: verbose?,
        min_impact: min_impact
      )
    end

    def execute
      parse_args
      return show_versions if version?
      return show_profiles if list_profiles?

      generate_report
    ensure
      @cleanup_paths.each do |d|
        debug "cleaning up #{d}"
        FileUtils.remove_entry(d, true)
      end
    end

    def generate_report
      product = inspec_profile.dup
      output = {}

      log_working_dir do |log_path|
        product ||= detect_product(log_path)
        spinner("Running inspec profile for #{product}") do
          output = reporter.report(inspec_exec(log_path, product))
        end
      end

      print_report('System report', output[:system_info])
      if output[:system_info].nil? && summary_only?
        error_msg "No system summary generated, #{product} not yet supported?"
      end
      print_report('gather-log report', output[:report]) unless summary_only?
    end

    def detect_product(log_path)
      debug 'Attempting to detect gatherlogs product...'
      Gatherlogs::Product.detect(log_path)
    end

    def show_profiles
      puts profiles.sort.join("\n").gsub('-wrapper', '')
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

      debug("Using log_path: #{current_log_path}")
      if File.directory?(current_log_path)
        yield current_log_path
      else
        yield extract_bundle(current_log_path)
      end
    end

    def tmpdir
      @cleanup_paths << (tmpdir = Dir.mktmpdir)
      tmpdir
    end

    def extract_bundle(filename)
      path = tmpdir
      cmd = [
        'tar', 'xvf', filename, '-C', path,
        '--strip-components', '2'
      ]
      spinner "Extracting log bundle" do
        shellout!(cmd)
        fix_archive_perms(path)
      end
      path
    end

    # it's possible for an archive to set permissions that prevent us from
    # accessing or removing files.  This fixes those permissions
    def fix_archive_perms(path)
      cmd = "find '#{path}' -type d -exec chmod 755 {} \\\;"
      shellout!(cmd)
      cmd = "find '#{path}' -type f -exec chmod 644 {} \\\;"
      shellout!(cmd)
    end

    def fetch_remote_tar(url)
      return if url.nil?

      tmp_cache_file = ::Tempfile.new('gatherlogs')
      tmp_cache_file.close
      debug "tmp_cache_file: #{tmp_cache_file.path}"

      spinner 'Fetching remote gatherlogs bundle' do
        shellout!(['wget', url, '-O', tmp_cache_file.path])
        @cleanup_paths << tmp_cache_file.path
      end

      tmp_cache_file.path
    end

    def find_profile_path(profile)
      path = File.join(::PROFILES_PATH, "#{profile}-wrapper")
      return path if File.exist?(path)

      raise "Couldn't find '#{profile}' profile, tried in '#{path}'"
    end

    def parse_args
      if debug?
        Gatherlogs.logger.level = ::Logger::DEBUG
        Inspec::Log.level = :debug
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

    def inspec_runner
      opts = {
        "logger" => Gatherlogs.logger,
        "report" => false,
        "reporter" => {
          "json" => { stdout: false }
        },
        "create_lockfile" => false
      }

      @inspec_runner ||= Inspec::Runner.new(opts)
    end

    def inspec_exec(path, product)
      signal_usage_error 'Please specify a profile to use' if product.nil?

      profile = find_profile_path(product)
      inspec_runner.add_target(profile)

      Dir.chdir(path) do
        inspec_runner.run
      end

      inspec_runner.report
    end
  end
end
