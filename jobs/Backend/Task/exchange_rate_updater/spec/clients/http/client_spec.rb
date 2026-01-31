# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Http::Client do
  let(:base_url) { 'https://api.example.com' }
  let(:client) { described_class.new(base_url: base_url) }

  describe '#get' do
    context 'when request is successful' do
      before do
        stub_request(:get, "#{base_url}/test")
          .to_return(status: 200, body: 'success response')
      end

      it 'returns a successful result' do
        result = client.get('/test')

        expect(result).to be_success
        expect(result.data).to eq('success response')
        expect(result.error).to be_nil
      end
    end

    context 'when request times out' do
      before do
        stub_request(:get, "#{base_url}/timeout")
          .to_timeout
      end

      it 'returns a failure result with timeout error' do
        result = client.get('/timeout')

        expect(result).to be_failure
        expect(result.error).to eq('execution expired')
        expect(result.error_type).to eq(:connection_error)
      end
    end

    context 'when connection fails' do
      before do
        stub_request(:get, "#{base_url}/error")
          .to_raise(Faraday::ConnectionFailed.new('Connection refused'))
      end

      it 'returns a failure result with connection error' do
        result = client.get('/error')

        expect(result).to be_failure
        expect(result.error).to eq('Connection refused')
        expect(result.error_type).to eq(:connection_error)
      end
    end

    context 'when request returns HTTP error status' do
      before do
        stub_request(:get, "#{base_url}/not-found")
          .to_return(status: 404, body: 'Not found')
      end

      it 'returns a failure result with HTTP error' do
        result = client.get('/not-found')

        expect(result).to be_failure
        expect(result.error).to eq('HTTP 404')
        expect(result.error_type).to eq(:http_error)
      end
    end

    context 'when request with query parameters' do
      before do
        stub_request(:get, "#{base_url}/search")
          .with(query: { q: 'test', limit: '10' })
          .to_return(status: 200, body: 'search results')
      end

      it 'sends query parameters correctly' do
        result = client.get('/search', params: { q: 'test', limit: '10' })

        expect(result).to be_success
        expect(result.data).to eq('search results')
      end
    end
  end
end
