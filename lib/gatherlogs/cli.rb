require 'json'
require 'mixlib/shellout'
require 'clamp'
require 'fileutils'

require "gatherlogs/product"
require "gatherlogs/reporter"

PROFILES_PATH = File.realpath(File.join(File.dirname(__FILE__), '../../profiles')).freeze
Clamp.allow_options_after_parameters = true

module Gatherlogs
  class CLI < Clamp::Command
    attr_accessor :current_log_path, :remote_cache_dir

    option ['-p', '--path'], 'PATH', 'Path to the gatherlogs for inspection', default: '.', attribute_name: :log_path
    option ['-r', '--remote'], 'REMOTE_URL', 'URL to the remote tar bal for inspection', attribute_name: :remote_url
    option ['-d', '--debug'], :flag, 'Enable debug output'
    option ['-s', '--system-only'], :flag, 'Only show system report', attribute_name: :summary_only
    option ['--profiles'], :flag, 'Show available profiles'
    option ['-v', '--verbose'], :flag, 'Show inspec test output'
    option ['-a', '--all'], :flag, 'Show all tests, default is to only show failed tests'
    option ['-q', '--quiet'], :flag, 'Only show the report output'
    option ['--version'], :flag, 'Show current version'

    parameter "[PROFILE]", "profile to execute", attribute_name: :inspec_profile

    def initialize(*args)
      super

      @current_log_path = nil
      @remote_cache_dir = nil
    end

    def execute()
      parse_args

      if version?
        puts "#{File.basename($0)}: #{Gatherlogs::VERSION}"
        exit
      end

      if profiles?
        possible_profiles = Dir.glob(File.join(PROFILES_PATH, '*/inspec.yml'))

        profiles = possible_profiles.map { |p| File.basename(File.dirname(p)) }
        profiles.reject! { |p| p == 'common' || p == 'glresources' }

        puts profiles.sort.join("\n")
        exit 0
      end


      @reporter = Gatherlogs::Reporter.new({
        all_controls: all?,
        verbose: verbose?,
        log_level: @log_level
      })

      product = inspec_profile.dup

      output = log_working_dir do |log_path|
        if product.nil?
          status_msg "Attempting to detect gatherlogs product..."
          product = Gatherlogs::Product.detect(log_path)
          status_msg "Detected '#{product}' files" unless product.nil?
        end

        if product.nil?
          signal_usage_error 'Could not determine the product from gatherlog bundle, please specify a profile to use'
        end

        @reporter.report(inspec_exec(product))
      end

      print_report('System report', output[:system_info])
      if output[:system_info].nil? && summary_only?
        puts "No system summary generated, #{product} not yet supported?"
      end
      print_report('Inspec report', output[:report]) unless summary_only?
    end

    def print_report(title, report)
      # this puts intentionally left blank
      puts ""
      puts title
      if report.is_a?(Hash)
        max_label_length = report.keys.map(&:length).max
        max_value_length = report.values.map(&:length).max
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

      debug_msg("Using log_path: #{current_log_path}")

      Dir.chdir(current_log_path) do
        return yield '.'
      end
    ensure
      FileUtils.remove_entry remote_cache_dir if remote_cache_dir && File.exists?(remote_cache_dir)
    end

    def fetch_remote_tar(url)
      status_msg "Fetching remote gatherlogs bundle"
      @remote_cache_dir = Dir.mktmpdir('gatherlogs')

      extension = remote_url.split('.').last
      local_filename = File.join(remote_cache_dir, "gatherlogs.#{extension}")

      cmd = ['wget', remote_url, '-O', local_filename]
      shellout!(cmd)

      debug_msg "Remote cache dir: #{remote_cache_dir}"

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
      @log_level = :debug if debug?
    end

    def system_report(product)
      status_msg "Generating system summary for #{product}..."
      system = Gatherlogs::Summary::System.new(product)
      system.report
    end

    def inspec_exec(product)
      status_msg "Using inspec version: #{shellout!('inspec --version').stdout.split("\n").first}"

      profile = find_profile_path(product)

      cmd = ['inspec', 'exec', profile, '--no-create-lockfile', '--reporter', 'json']

      status_msg "Running inspec..."
      debug_msg('Executing', "'#{cmd}'")

      inspec = shellout!(cmd, { returns: [0, 100, 101] })
      JSON.parse(inspec.stdout)
    end

    def status_msg(*msg)
      STDERR.puts(msg.join(' ')) unless quiet?
    end

    def debug_msg(*msg)
      STDERR.puts(msg.join(' ')) if debug?
    end

    def shellout!(cmd, options={})
      puts Array(cmd).join(' ') if debug?
      shell = Mixlib::ShellOut.new(cmd, options)
      shell.run_command
      shell.error!
      shell
    end
  end
end
