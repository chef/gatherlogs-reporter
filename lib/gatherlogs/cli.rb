require 'json'
require 'mixlib/shellout'
require 'clamp'
require "gatherlogs/version"
require "gatherlogs/product"

PROFILES_PATH = File.realpath(File.join(File.dirname(__FILE__), '../../profiles')).freeze
Clamp.allow_options_after_parameters = true

module Gatherlogs
  class CLI < Clamp::Command
    option ['--path'], 'PATH', 'Path to the gatherlogs for inspection', default: '.', attribute_name: :log_path
    option ['-d', '--debug'], :flag, 'enable debug output'
    option ['-p', '--profiles'], :flag, 'show available profiles'
    option ['-v', '--verbose'], :flag, 'show inspec test output'
    option ['-a', '--all'], :flag, 'show all tests'

    parameter "[PROFILE]", "profile to execute", attribute_name: :inspec_profile

    def execute()
      parse_args

      if profiles?
        possible_profiles = Dir.glob(File.join(PROFILES_PATH, '*/inspec.yml'))

        profiles = possible_profiles.map { |p| File.basename(File.dirname(p)) }
        profiles.reject! { |p| p == 'common' || p == 'glresources' }

        puts profiles.sort.join("\n")
        exit 0
      end

      profile = nil
      if inspec_profile
        profile = inspec_profile.dup
      else
        status_msg "Attempting to detect gatherlogs product..."
        profile = Gatherlogs::Product.detect(log_path)
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
      report_json = inspec_exec(profile_path)

      status_msg "Generating report..."
      puts @reporter.report(report_json)
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

    def inspec_exec(profile)
      cmd = ['inspec', 'exec', profile, '--reporter', 'json'].join(' ')

      status_msg "Running inspec..."
      debug_msg('Executing', "'#{cmd}'")

      Dir.chdir(log_path) do
        inspec = shellout(cmd, { returns: [0, 100, 101] })
        JSON.parse(inspec.stdout)
      end
    end

    def status_msg(*msg)
      STDERR.puts(msg.join(' '))
    end

    def debug_msg(*msg)
      STDERR.puts(msg.join(' ')) if debug?
    end

    def shellout(cmd, options={})
      # puts cmd
      shell = Mixlib::ShellOut.new(cmd, options)
      shell.run_command
      shell.error!
      shell
    end
  end
end
