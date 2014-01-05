require File.dirname(__FILE__) + '/../lib/ruby_path'
require 'json'

require 'rspec'
RSpec.configure do |config|
  config.mock_framework = :rspec
end

def fixture_path
  File.expand_path('../fixtures', __FILE__)
end