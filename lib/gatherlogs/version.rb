require 'gatherlogs/shellout'

module Gatherlogs
  BASE_PATH = File.join(File.dirname(__FILE__), '../..')
  VERSION = File.read(File.join(BASE_PATH, 'VERSION'))

  module Version
    extend Gatherlogs::Shellout

    def self.inspec_version
      if Gem.loaded_specs.include?('inspec-core')
        inspec_version = 'inspec-core: '
        inspec_version += Gem.loaded_specs['inspec-core'].version.to_s
      elsif Gem.loaded_specs.include?('inspec')
        inspec_version = 'inspec: '
        inspec_version += Gem.loaded_specs['inspec'].version.to_s
      else
        inspec_version = 'Unable to find inspec gem'
      end

      inspec_version
    end

    def self.cli_version
      "gatherlog: #{Gatherlogs::VERSION}"
    end

    def self.show
      puts Gatherlogs::Version.cli_version
      puts Gatherlogs::Version.inspec_version
    end
  end
end
