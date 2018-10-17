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
    option ['--profiles'], :flag, 'Show available profiles'
    option ['-v', '--verbose'], :flag, 'Show inspec test output'
    option ['-a', '--all'], :flag, 'Show all tests, default is to only show failed tests'
    option ['--version'], :flag, 'Show current version'

    parameter "[PROFILE]", "profile to execute", attribute_name: :inspec_profile

    def initialize(*args)
      super

      @current_log_path = nil
      @remote_cache_dir = nil
    end

    def execute()
      parse_args

      current_log_path = log_path.dup

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

      current_log_path = fetch_remote_tar(remote_url) unless remote_url.nil?

      debug_msg("Using log_path: #{current_log_path}")

      profile = nil
      if inspec_profile
        profile = inspec_profile.dup
      else
        status_msg "Attempting to detect gatherlogs product..."
        profile = Gatherlogs::Product.detect(current_log_path)
        status_msg "Detected '#{profile}' files" unless profile.nil?
      end

      if profile.nil?
        signal_usage_error 'Could not determine product profile to use, please specify a profile'
      end

      @reporter = Gatherlogs::Reporter.new({
        all_controls: all?,
        verbose: verbose?,
        log_level: @log_level
      })

      profile_path = find_profile_path(profile)
      report_json = inspec_exec(profile_path, current_log_path)

      status_msg "Generating report..."
      puts @reporter.report(report_json)
    ensure
      FileUtils.remove_entry remote_cache_dir
    end

    def fetch_remote_tar(url)
      @remote_cache_dir = Dir.mktmpdir('gatherlogs')
      
      extension = remote_url.split('.').last
      local_filename = File.join(remote_cache_dir, "gatherlogs.#{extension}")

      cmd = ['wget', remote_url, '-O', local_filename]
      shellout!(cmd)

      debug_msg "Remote cache dir: #{remote_cache_dir}"

      cmd = ['tar', 'xvfz', local_filename, '-C', remote_cache_dir, '--strip-components', '2']
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

    def inspec_exec(profile, log_path)
      cmd = ['inspec', 'exec', profile, '--no-create-lockfile', '--reporter', 'json']

      status_msg "Running inspec..."
      debug_msg('Executing', "'#{cmd}'")

      Dir.chdir(log_path) do
        inspec = shellout!(cmd, { returns: [0, 100, 101] })
        JSON.parse(inspec.stdout)
      end
    end

    def status_msg(*msg)
      STDERR.puts(msg.join(' '))
    end

    def debug_msg(*msg)
      STDERR.puts(msg.join(' ')) if debug?
    end

    def shellout!(cmd, options={})
      puts cmd.join(' ') if debug?
      shell = Mixlib::ShellOut.new(cmd, options)
      shell.run_command
      shell.error!
      shell
    end
  end
end
