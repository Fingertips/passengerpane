begin
  require 'rubygems'
rescue LoadError
end

require 'test/spec'
require 'mocha'
require 'osx/cocoa'

$:.unshift File.expand_path('../test_helper', __FILE__)
require 'objective-c'

# Well, you know how it goes…
NO  = 0
YES = 1
DEVELOPMENT = 0
PRODUCTION  = 1