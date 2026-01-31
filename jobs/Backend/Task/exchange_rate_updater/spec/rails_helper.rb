require 'spec_helper'

ENV['RAILS_ENV'] ||= 'test'

require_relative '../config/environment'

# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
require 'webmock/rspec'
require 'factory_bot_rails'

# Disable external HTTP requests (allow localhost for Rails server)
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  # Include FactoryBot syntax methods
  config.include FactoryBot::Syntax::Methods

  # Remove this line to enable support for ActiveRecord
  config.use_active_record = false

  config.filter_rails_from_backtrace!
end
