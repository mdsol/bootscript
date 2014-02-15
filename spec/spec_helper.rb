require 'bundler'
Bundler.setup
require 'rspec'
RSpec.configure do |c|
  c.mock_with :rspec
end
require 'bootscript'
