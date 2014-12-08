require 'bundler/setup'
Bundler.setup

require 'oops'

Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  # some (optional) config here
end
