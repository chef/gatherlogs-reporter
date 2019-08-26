require 'rubygems'

require 'gatherlogs/version'
require 'gatherlogs/product'
require 'gatherlogs/reporter'
require 'logger'

module Gatherlogs
  def self.logger
    @logger ||= ::Logger.new(STDERR)
  end

  def self.logger=(custom_logger)
    @logger = custom_logger
  end
end
