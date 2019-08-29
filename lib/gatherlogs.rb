require 'rubygems'
require 'json'
require 'clamp'
require 'fileutils'
require 'logger'
require 'tempfile'
require 'inspec'

require 'gatherlogs/version'
require 'gatherlogs/product'
require 'gatherlogs/profiles'
require 'gatherlogs/reporter'
require 'gatherlogs/shellout'
require 'logger'

module Gatherlogs
  def self.logger
    @logger ||= ::Logger.new(STDERR)
  end

  def self.logger=(custom_logger)
    @logger = custom_logger
  end
end
