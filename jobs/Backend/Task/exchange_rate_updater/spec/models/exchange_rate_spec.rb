# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExchangeRate, type: :model do
  describe 'validations' do
    it 'is valid with all required attributes' do
      rate = build(:exchange_rate)
      expect(rate).to be_valid
    end

    it 'is invalid without source_currency' do
      rate = build(:exchange_rate, source_currency: nil)
      expect(rate).not_to be_valid
      expect(rate.errors[:source_currency]).to include("can't be blank")
    end

    it 'is invalid without target_currency' do
      rate = build(:exchange_rate, target_currency: nil)
      expect(rate).not_to be_valid
      expect(rate.errors[:target_currency]).to include("can't be blank")
    end

    it 'is invalid without rate' do
      rate = build(:exchange_rate, :invalid)
      expect(rate).not_to be_valid
      expect(rate.errors[:rate]).to include("can't be blank")
    end

    it 'is invalid with zero rate' do
      rate = build(:exchange_rate, rate: 0)
      expect(rate).not_to be_valid
      expect(rate.errors[:rate]).to include('must be greater than 0')
    end

    it 'is invalid with negative rate' do
      rate = build(:exchange_rate, rate: -5)
      expect(rate).not_to be_valid
      expect(rate.errors[:rate]).to include('must be greater than 0')
    end

    it 'is invalid with zero amount' do
      rate = build(:exchange_rate, amount: 0)
      expect(rate).not_to be_valid
      expect(rate.errors[:amount]).to include('must be greater than 0')
    end
  end

  describe '#initialize' do
    it 'converts currencies to uppercase' do
      rate = ExchangeRate.new(
        source_currency: 'usd',
        target_currency: 'czk',
        rate: 23.5,
        amount: 1,
        date: Date.today
      )
      expect(rate.source_currency).to eq('USD')
      expect(rate.target_currency).to eq('CZK')
    end
  end

  describe '#normalized_rate' do
    it 'returns rate divided by amount for single unit' do
      rate = build(:exchange_rate, rate: 23.456, amount: 1)
      expect(rate.normalized_rate).to eq(23.456)
    end

    it 'returns rate divided by amount for multi-unit rate' do
      rate = build(:exchange_rate, :jpy, rate: 17.567, amount: 100)
      expect(rate.normalized_rate).to eq(0.17567)
    end
  end

  describe '#to_s' do
    it 'returns a human-readable string' do
      rate = build(:exchange_rate, source_currency: 'USD', target_currency: 'CZK', rate: 23.5, amount: 1)
      expected = "1 USD = 23.5 CZK (#{Date.today})"
      expect(rate.to_s).to eq(expected)
    end

    it 'includes amount for multi-unit rates' do
      rate = build(:exchange_rate, :jpy, source_currency: 'JPY', target_currency: 'CZK', rate: 17.5, amount: 100)
      expected = "100 JPY = 17.5 CZK (#{Date.today})"
      expect(rate.to_s).to eq(expected)
    end
  end

  describe '#as_json' do
    it 'returns a hash with all attributes' do
      rate = build(:exchange_rate, source_currency: 'USD', target_currency: 'CZK', rate: 23.456, amount: 1)
      json = rate.as_json

      expect(json[:source_currency]).to eq('USD')
      expect(json[:target_currency]).to eq('CZK')
      expect(json[:rate]).to eq(23.456)
      expect(json[:amount]).to eq(1)
      expect(json[:normalized_rate]).to eq(23.456)
      expect(json[:date]).to eq(Date.today.iso8601)
    end

    it 'raises error for invalid exchange rate' do
      rate = build(:exchange_rate, :invalid)
      expect { rate.as_json }.to raise_error('Cannot serialize invalid ExchangeRate')
    end
  end
end
