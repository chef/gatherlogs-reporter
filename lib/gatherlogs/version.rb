require 'gatherlogs/shellout'

module Gatherlogs
  BASE_PATH = File.join(File.dirname(__FILE__), '../..')
  VERSION = File.read(File.join(BASE_PATH, 'VERSION'))

  module Version
    extend Gatherlogs::Shellout

    def self.inspec_version
      "inspec: #{shellout!('inspec --version').stdout.lines.first}"
    end

    def self.cli_version
      "check_logs: #{Gatherlogs::VERSION}"
    end
  end
end
