# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Exchange Rates', type: :request do
  let(:mock_service) { instance_double(CnbExchangeRateProviderService) }

  before do
    allow(CnbExchangeRateProviderService).to receive(:new).and_return(mock_service)
  end

  describe 'GET /api/v1/exchange_rates' do
    context 'when service returns success' do
      let(:exchange_rates) do
        [
          build(:exchange_rate, source_currency: 'USD', rate: 23.456),
          build(:exchange_rate, :eur, rate: 25.234)
        ]
      end

      before do
        allow(mock_service).to receive(:call).and_return(
          ServiceResult::Result.new(true, exchange_rates, [])
        )
      end

      it 'returns successful response with exchange rates' do
        get '/api/v1/exchange_rates'

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('application/json')

        json = JSON.parse(response.body)
        expect(json).to be_an(Array)
        expect(json.size).to eq(2)
        expect(json.first['source_currency']).to eq('USD')
        expect(json.first['target_currency']).to eq('CZK')
        expect(json.first['rate']).to eq(23.456)
      end

      it 'passes nil when no currencies parameter provided' do
        get '/api/v1/exchange_rates'

        expect(mock_service).to have_received(:call).with(nil)
      end

      it 'passes currencies parameter to service' do
        get '/api/v1/exchange_rates', params: { currencies: 'USD,EUR' }

        expect(mock_service).to have_received(:call).with('USD,EUR')
      end

      it 'handles array currencies parameter' do
        get '/api/v1/exchange_rates', params: { currencies: %w[USD EUR] }

        expect(mock_service).to have_received(:call).with(%w[USD EUR])
      end
    end

    context 'when service returns failure' do
      before do
        allow(mock_service).to receive(:call).and_return(
          ServiceResult::Result.new(false, nil, ['CNB API is unavailable'])
        )
      end

      it 'returns unprocessable entity status' do
        get '/api/v1/exchange_rates'

        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json['errors']).to include('CNB API is unavailable')
      end
    end

    context 'when invalid currency format provided' do
      before do
        allow(mock_service).to receive(:call).and_return(
          ServiceResult::Result.new(true, [], [])
        )
      end

      it 'logs warning but continues processing' do
        expect(Rails.logger).to receive(:warn).with(/Invalid Currency Format/)

        get '/api/v1/exchange_rates', params: { currencies: 'INVALID' }

        expect(response).to have_http_status(:ok)
      end

      it 'accepts valid currency codes' do
        get '/api/v1/exchange_rates', params: { currencies: 'USD' }

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when unexpected error occurs' do
      before do
        allow(mock_service).to receive(:call).and_raise(StandardError.new('Unexpected'))
      end

      it 'returns internal server error' do
        expect(Rails.logger).to receive(:error).with(/Unexpected Error/)

        get '/api/v1/exchange_rates'

        expect(response).to have_http_status(:internal_server_error)

        json = JSON.parse(response.body)
        expect(json['error']).to eq('Internal server error')
      end
    end
  end
end
