# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Exchange Rates', type: :request do
  describe 'GET /exchange_rates' do
    context 'when service returns success' do
      let(:exchange_rates) do
        [
          build(:exchange_rate, source_currency: 'USD', rate: 23.456),
          build(:exchange_rate, :eur, rate: 25.234),
          build(:exchange_rate, source_currency: 'GBP', rate: 28.789)
        ]
      end

      before do
        allow_any_instance_of(CnbExchangeRateProviderService).to receive(:call)
          .and_return(ServiceResult::Result.new(true, exchange_rates, []))
      end

      it 'returns successful response' do
        get '/exchange_rates'

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Czech National Bank Exchange Rates')
      end

      it 'displays all exchange rates' do
        get '/exchange_rates'

        expect(response.body).to include('USD')
        expect(response.body).to include('EUR')
        expect(response.body).to include('GBP')
      end

      it 'shows rate count' do
        get '/exchange_rates'

        expect(response.body).to include('Showing <strong>3</strong> exchange rates')
      end

      it 'displays currency filter checkboxes' do
        get '/exchange_rates'

        expect(response.body).to include('currency_USD')
        expect(response.body).to include('currency_EUR')
        expect(response.body).to include('currency_GBP')
      end
    end

    context 'when filtering by currencies' do
      let(:usd_rate) { build(:exchange_rate, source_currency: 'USD', rate: 23.456) }

      before do
        allow_any_instance_of(CnbExchangeRateProviderService).to receive(:call)
          .and_return(ServiceResult::Result.new(true, [usd_rate], []))
      end

      it 'passes currencies parameter to service' do
        expect_any_instance_of(CnbExchangeRateProviderService).to receive(:call)
          .with(['USD', 'EUR'])

        get '/exchange_rates', params: { currencies: %w[USD EUR] }
      end

      it 'displays filtered rates' do
        get '/exchange_rates', params: { currencies: ['USD'] }

        expect(response.body).to include('USD')
        expect(response.body).to include('Showing <strong>1</strong> exchange rate')
      end
    end

    context 'when service returns failure' do
      before do
        allow_any_instance_of(CnbExchangeRateProviderService).to receive(:call)
          .and_return(ServiceResult::Result.new(false, nil, ['CNB API error']))
      end

      it 'displays error message' do
        get '/exchange_rates'

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Error')
        expect(response.body).to include('CNB API error')
      end

      it 'shows empty state' do
        get '/exchange_rates'

        expect(response.body).to include('No exchange rates available')
      end
    end

    context 'when no rates available' do
      before do
        allow_any_instance_of(CnbExchangeRateProviderService).to receive(:call)
          .and_return(ServiceResult::Result.new(true, [], []))
      end

      it 'displays empty state' do
        get '/exchange_rates'

        expect(response.body).to include('No exchange rates available')
      end
    end
  end
end
