# frozen_string_literal: true

module Api
  module V1
    # RESTful API for fetching CNB exchange rates
    # Returns JSON responses with exchange rate data
    class ExchangeRatesController < Api::BaseController
      before_action :validate_currency_format, if: -> { params[:currencies].present? }

      # GET /api/v1/exchange_rates?currencies=USD,EUR,GBP
      # Returns exchange rates for specified currencies
      def index
        result = CnbExchangeRateProviderService.call(params[:currencies])

        if result.success?
          render json: result.result, status: :ok
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      rescue StandardError => e
        Rails.logger.error("[Unexpected Error] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
        render json: { error: 'Internal server error' }, status: :internal_server_error
      end

      private

      # rubocop:disable Metrics/AbcSize
      def validate_currency_format
        currencies = Array.wrap(params[:currencies]).flat_map { |c| c.to_s.split(',') }.map(&:strip)

        invalid = currencies.select do |c|
          c.blank? || c.length != 3 || !c.match?(/\A[A-Z]{3}\z/i)
        end

        return unless invalid.any?

        Rails.logger.warn("[Invalid Currency Format] Received malformed currency codes: #{invalid.join(', ')}")
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
