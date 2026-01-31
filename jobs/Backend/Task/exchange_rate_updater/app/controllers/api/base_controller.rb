# frozen_string_literal: true

module Api
  class BaseController < ActionController::API
    # API-specific configuration
    # Excludes CSRF, sessions, cookies, flash, etc.
  end
end
