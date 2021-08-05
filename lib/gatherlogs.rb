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

module Gatherlogs
  def self.logger
    @logger ||= ::Logger.new($stderr)
  end

  def self.logger=(custom_logger)
    @logger = custom_logger
  end
end
