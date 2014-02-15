require 'bundler'
Bundler.setup
require "#{File.dirname __FILE__}/unpacker"
require 'rspec'
RSpec.configure do |c|
  c.mock_with :rspec
end
require 'bootscript'
