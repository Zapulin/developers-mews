# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'API V1 Exchange Rates', type: :request do
  path '/api/v1/exchange_rates' do
    get 'Retrieves exchange rates from Czech National Bank' do
      tags 'Exchange Rates'
      produces 'application/json'
      
      parameter name: :currencies,
                in: :query,
                type: :string,
                required: false,
                description: 'Comma-separated currency codes (e.g., USD,EUR,GBP). Returns all rates if omitted.'

      response '200', 'Exchange rates retrieved successfully' do
        schema type: :array,
               items: {
                 type: :object,
                 properties: {
                   source_currency: { type: :string, example: 'USD' },
                   target_currency: { type: :string, example: 'CZK' },
                   rate: { type: :number, format: :float, example: 23.456 },
                   amount: { type: :integer, example: 1 },
                   normalized_rate: { type: :number, format: :float, example: 23.456 },
                   date: { type: :string, format: :date, example: '2026-01-31' }
                 },
                 required: %w[source_currency target_currency rate amount normalized_rate date]
               }

        let(:exchange_rates) do
          [
            build(:exchange_rate, source_currency: 'USD', rate: 23.456),
            build(:exchange_rate, :eur, rate: 25.234)
          ]
        end

        before do
          allow_any_instance_of(CnbExchangeRateProviderService).to receive(:call)
            .and_return(ServiceResult::Result.new(true, exchange_rates, []))
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
          expect(data.first['source_currency']).to eq('USD')
        end
      end

      response '200', 'Filter by specific currencies' do
        let(:currencies) { 'USD,EUR' }

        let(:exchange_rates) do
          [build(:exchange_rate, source_currency: 'USD', rate: 23.456)]
        end

        before do
          allow_any_instance_of(CnbExchangeRateProviderService).to receive(:call)
            .and_return(ServiceResult::Result.new(true, exchange_rates, []))
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.size).to eq(1)
        end
      end

      response '422', 'Service error (e.g., CNB API unavailable)' do
        schema type: :object,
               properties: {
                 errors: {
                   type: :array,
                   items: { type: :string },
                   example: ['Failed to fetch exchange rates: Connection failed']
                 }
               }

        before do
          allow_any_instance_of(CnbExchangeRateProviderService).to receive(:call)
            .and_return(ServiceResult::Result.new(false, nil, ['CNB API unavailable']))
        end

        run_test!
      end

      response '500', 'Internal server error' do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'Internal server error' }
               }

        before do
          allow_any_instance_of(CnbExchangeRateProviderService).to receive(:call)
            .and_raise(StandardError.new('Unexpected'))
        end

        run_test!
      end
    end
  end
end
