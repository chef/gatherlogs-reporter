libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'gatherlogs/version'
require 'gatherlogs/reporter'

module Gatherlogs
end
