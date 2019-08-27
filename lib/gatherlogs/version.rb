require 'gatherlogs/shellout'

module Gatherlogs
  BASE_PATH = File.join(File.dirname(__FILE__), '../..')
  VERSION = File.read(File.join(BASE_PATH, 'VERSION'))

  module Version
    extend Gatherlogs::Shellout

    def self.inspec_version
      "inspec: #{Gem.loaded_specs['inspec-core'].version}"
    end

    def self.cli_version
      "gatherlogs_report: #{Gatherlogs::VERSION}"
    end
  end
end
