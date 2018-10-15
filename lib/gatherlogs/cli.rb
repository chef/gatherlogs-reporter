require 'json'
require 'mixlib/shellout'
require 'clamp'
require "gatherlogs/version"

PROFILES_PATH = File.realpath(File.join(File.dirname(__FILE__), '../../profiles')).freeze
Clamp.allow_options_after_parameters = true

module Gatherlogs
  class CLI < Clamp::Command
    option ['-d', '--debug'], :flag, 'enable debug output'
    option ['-p', '--profiles'], :flag, 'show available profiles'
    option ['-v', '--verbose'], :flag, 'show inspec test output'
    option ['-a', '--all'], :flag, 'show all tests'

    parameter "[PROFILE]", "profile to execute", attribute_name: :profile

    def execute()
      parse_args

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
        raise "Couldn't find #{profile}, tried: #{path}"
      end
    end

    def parse_args
      @log_level = :debug if debug?
    end

    def inspec_exec(profile)
      cmd = ['inspec', 'exec', profile, '--reporter', 'json'].join(' ')

      status_msg "Running inspec..."
      debug_msg('Executing', "'#{cmd}'")
      inspec = shellout(cmd, { returns: [0,100] })

      JSON.parse(inspec.stdout)
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
