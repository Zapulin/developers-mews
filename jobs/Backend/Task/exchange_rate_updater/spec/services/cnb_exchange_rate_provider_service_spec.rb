# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CnbExchangeRateProviderService do
  let(:mock_client) { instance_double(Http::CnbClient) }
  let(:service) { described_class.new(http_client: mock_client) }

  let(:cnb_response) do
    <<~CNB
      31 Jan 2026 #21
      Country|Currency|Amount|Code|Rate
      Australia|dollar|1|AUD|15.123
      EMU|euro|1|EUR|25.234
      Japan|yen|100|JPY|17.567
      USA|dollar|1|USD|23.456
    CNB
  end

  before do
    Rails.cache.clear
  end

  describe '.call' do
    it 'creates instance and calls the service' do
      allow(mock_client).to receive(:fetch_daily).and_return(
        Http::Result.new(true, cnb_response, nil, nil)
      )

      result = described_class.call(['USD'], http_client: mock_client)

      expect(result).to be_success
      expect(result.result.size).to eq(1)
    end
  end

  describe '#call' do
    context 'when currencies parameter is nil' do
      before do
        allow(mock_client).to receive(:fetch_daily).and_return(
          Http::Result.new(true, cnb_response, nil, nil)
        )
      end

      it 'returns all exchange rates' do
        result = service.call(nil)

        expect(result).to be_success
        expect(result.result.size).to eq(4)
        expect(result.result.map(&:source_currency)).to match_array(%w[AUD EUR JPY USD])
      end
    end

    context 'when currencies parameter is empty' do
      before do
        allow(mock_client).to receive(:fetch_daily).and_return(
          Http::Result.new(true, cnb_response, nil, nil)
        )
      end

      it 'returns all exchange rates' do
        result = service.call([])

        expect(result).to be_success
        expect(result.result.size).to eq(4)
      end
    end

    context 'when requesting specific currencies' do
      before do
        allow(mock_client).to receive(:fetch_daily).and_return(
          Http::Result.new(true, cnb_response, nil, nil)
        )
      end

      it 'returns only requested currencies as string' do
        result = service.call('USD,EUR')

        expect(result).to be_success
        expect(result.result.size).to eq(2)
        expect(result.result.map(&:source_currency)).to match_array(%w[USD EUR])
      end

      it 'returns only requested currencies as array' do
        result = service.call(%w[USD EUR])

        expect(result).to be_success
        expect(result.result.size).to eq(2)
        expect(result.result.map(&:source_currency)).to match_array(%w[USD EUR])
      end

      it 'handles Currency objects' do
        currencies = [Currency.new('USD'), Currency.new('EUR')]
        result = service.call(currencies)

        expect(result).to be_success
        expect(result.result.size).to eq(2)
      end

      it 'filters out non-existent currencies' do
        result = service.call('USD,XYZ')

        expect(result).to be_success
        expect(result.result.size).to eq(1)
        expect(result.result.first.source_currency).to eq('USD')
      end
    end

    context 'when parsing CNB data' do
      before do
        allow(mock_client).to receive(:fetch_daily).and_return(
          Http::Result.new(true, cnb_response, nil, nil)
        )
      end

      it 'parses exchange rates correctly' do
        result = service.call('USD')

        rate = result.result.first
        expect(rate.source_currency).to eq('USD')
        expect(rate.target_currency).to eq('CZK')
        expect(rate.rate).to eq(23.456)
        expect(rate.amount).to eq(1)
        expect(rate.date).to eq(Date.new(2026, 1, 31))
      end

      it 'parses multi-unit rates correctly' do
        result = service.call('JPY')

        rate = result.result.first
        expect(rate.source_currency).to eq('JPY')
        expect(rate.amount).to eq(100)
        expect(rate.rate).to eq(17.567)
      end

      it 'parses comma decimal separators correctly' do
        cnb_with_commas = <<~CNB
          31 Jan 2026 #21
          Country|Currency|Amount|Code|Rate
          EMU|euro|1|EUR|25,234
        CNB

        allow(mock_client).to receive(:fetch_daily).and_return(
          Http::Result.new(true, cnb_with_commas, nil, nil)
        )

        result = service.call('EUR')
        rate = result.result.first
        expect(rate.rate).to eq(25.234)
      end
    end

    context 'when HTTP client fails' do
      before do
        allow(mock_client).to receive(:fetch_daily).and_return(
          Http::Result.new(false, nil, 'Connection failed', :connection_error)
        )
      end

      it 'returns a failure result' do
        result = service.call('USD')

        expect(result).to be_failure
        expect(result.errors.first).to include('Failed to fetch exchange rates')
      end
    end

    context 'when CNB data is malformed' do
      before do
        allow(mock_client).to receive(:fetch_daily).and_return(
          Http::Result.new(true, '', nil, nil)
        )
      end

      it 'returns a failure result' do
        result = service.call('USD')

        expect(result).to be_failure
        expect(result.errors.first).to include('Failed to parse CNB data')
      end
    end

    context 'when CNB data has invalid lines' do
      let(:partial_cnb_response) do
        <<~CNB
          31 Jan 2026 #21
          Country|Currency|Amount|Code|Rate
          USA|dollar|1|USD|23.456
          Invalid|Line|Here
          EMU|euro|1|EUR|25.234
        CNB
      end

      before do
        allow(mock_client).to receive(:fetch_daily).and_return(
          Http::Result.new(true, partial_cnb_response, nil, nil)
        )
      end

      it 'skips invalid lines and continues parsing' do
        result = service.call(nil)

        expect(result).to be_success
        expect(result.result.size).to eq(2)
        expect(result.result.map(&:source_currency)).to match_array(%w[USD EUR])
      end
    end

    context 'when using cache' do
      around do |example|
        original_cache = Rails.cache
        Rails.cache = ActiveSupport::Cache::MemoryStore.new
        example.run
        Rails.cache = original_cache
      end

      before do
        Rails.cache.clear
        allow(mock_client).to receive(:fetch_daily).and_return(
          Http::Result.new(true, cnb_response, nil, nil)
        )
      end

      it 'caches the results across multiple calls' do
        service.call('USD')
        service.call('EUR')

        expect(mock_client).to have_received(:fetch_daily).once
      end

      it 'uses cached data for subsequent calls' do
        first_result = service.call('USD')
        expect(first_result).to be_success
        
        second_result = service.call('USD')
        expect(second_result).to be_success
        expect(second_result.result.first.source_currency).to eq('USD')
        
        expect(mock_client).to have_received(:fetch_daily).once
      end
    end

    context 'when unexpected error occurs' do
      before do
        allow(mock_client).to receive(:fetch_daily).and_raise(StandardError.new('Unexpected'))
      end

      it 'returns a failure result with error message' do
        result = service.call('USD')

        expect(result).to be_failure
        expect(result.errors.first).to include('Unexpected')
      end
    end
  end
end
