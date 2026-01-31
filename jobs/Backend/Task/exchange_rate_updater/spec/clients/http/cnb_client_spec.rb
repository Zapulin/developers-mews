# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Http::CnbClient do
  let(:client) { described_class.new }

  describe '#fetch_daily' do
    let(:cnb_response) do
      <<~CNB
        31 Jan 2026 #21
        Country|Currency|Amount|Code|Rate
        Australia|dollar|1|AUD|15.123
        EMU|euro|1|EUR|25.234
        USA|dollar|1|USD|23.456
      CNB
    end

    context 'when CNB API responds successfully' do
      before do
        stub_request(:get, "https://www.cnb.cz#{described_class::DAILY_PATH}")
          .to_return(status: 200, body: cnb_response)
      end

      it 'returns a successful result with CNB data' do
        result = client.fetch_daily

        expect(result).to be_success
        expect(result.data).to include('31 Jan 2026')
        expect(result.data).to include('USD|23.456')
      end
    end

    context 'when CNB API is unreachable' do
      before do
        stub_request(:get, "https://www.cnb.cz#{described_class::DAILY_PATH}")
          .to_timeout
      end

      it 'returns a failure result' do
        result = client.fetch_daily

        expect(result).to be_failure
        expect(result.error_type).to eq(:connection_error)
      end
    end

    context 'when CNB API returns error' do
      before do
        stub_request(:get, "https://www.cnb.cz#{described_class::DAILY_PATH}")
          .to_return(status: 503, body: 'Service Unavailable')
      end

      it 'returns a failure result' do
        result = client.fetch_daily

        expect(result).to be_failure
        expect(result.error).to eq('HTTP 503')
        expect(result.error_type).to eq(:http_error)
      end
    end
  end
end
