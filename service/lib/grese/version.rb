module Grese
  BASE_PATH = File.join(File.dirname(__FILE__), '../..')
  VERSION = File.read(File.join(BASE_PATH, '../VERSION'))

  module Version
    def self.version
      "grese: #{Grese::VERSION}"
    end
  end
end
