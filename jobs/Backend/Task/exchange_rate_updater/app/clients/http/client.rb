# frozen_string_literal: true

require 'faraday'
require 'faraday/retry'

module Http
  # Generic HTTP client with retry logic, timeouts, and error handling.
  # Base class for specific API clients (e.g., CnbClient).
  class Client
    attr_reader :connection

    def initialize(base_url:, headers: {}, timeout: 10)
      @connection = Faraday.new(url: base_url) do |f|
        f.request :retry, max: 3, interval: 0.5, backoff_factor: 2
        f.headers.update(default_headers.merge(headers))
        f.options.timeout = timeout
        f.options.open_timeout = timeout
        f.adapter Faraday.default_adapter
      end
    end

    def get(path, params: {})
      perform_request { connection.get(path, params) }
    end

    # Future methods can reuse the same error handling
    # def post(path, body:, params: {})
    #   perform_request { connection.post(path, body, params) }
    # end

    private

    def perform_request
      response = yield
      build_result(response)
    rescue Faraday::TimeoutError => e
      handle_timeout_error(e)
    rescue Faraday::ConnectionFailed => e
      handle_connection_error(e)
    rescue StandardError => e
      handle_unknown_error(e)
    end

    def handle_timeout_error(_error)
      Rails.logger.error("HTTP request timeout: #{connection.url_prefix}")
      Result.new(false, nil, 'Request timed out', :timeout)
    end

    def handle_connection_error(error)
      Rails.logger.error("HTTP connection failed: #{connection.url_prefix} - #{error.message}")
      Result.new(false, nil, error.message, :connection_error)
    end

    def handle_unknown_error(error)
      Rails.logger.error("HTTP unknown error: #{connection.url_prefix} - #{error.message}")
      Result.new(false, nil, error.message, :unknown)
    end

    def build_result(response)
      body = response.body.to_s.strip

      if response.success?
        Result.new(true, body, nil, nil)
      else
        Result.new(false, nil, "HTTP #{response.status}", :http_error)
      end
    end

    def default_headers
      {
        'Accept' => '*/*'
      }
    end
  end
end
