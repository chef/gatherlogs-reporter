require 'gatherlogs/version'
require 'gatherlogs/product'
require 'gatherlogs/reporter'
require 'gatherlogs/output'

module Gatherlogs
  extend Gatherlogs::Output

  def self.logger
    if @logger.nil?
      @logger = Logger.new(STDERR)
      @logger.level = Logger::INFO
      enable_colors
    end
    @logger
  end

  def self.logger=(l)
    @logger = l
  end
end
