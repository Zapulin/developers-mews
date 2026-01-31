# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Currency, type: :model do
  describe '#initialize' do
    it 'converts code to uppercase' do
      currency = Currency.new('usd')
      expect(currency.code).to eq('USD')
    end

    it 'accepts uppercase code' do
      currency = Currency.new('EUR')
      expect(currency.code).to eq('EUR')
    end
  end

  describe 'validations' do
    it 'is valid with a 3-letter code' do
      currency = build(:currency, code: 'USD')
      expect(currency).to be_valid
    end

    it 'is invalid without a code' do
      currency = Currency.new(nil)
      expect(currency).not_to be_valid
      expect(currency.errors[:code]).to include("can't be blank")
    end

    it 'is invalid with a code shorter than 3 letters' do
      currency = Currency.new('US')
      expect(currency).not_to be_valid
      expect(currency.errors[:code]).to include('is the wrong length (should be 3 characters)')
    end

    it 'is invalid with a code longer than 3 letters' do
      currency = Currency.new('USDA')
      expect(currency).not_to be_valid
      expect(currency.errors[:code]).to include('is the wrong length (should be 3 characters)')
    end

    it 'is invalid with non-alphabetic characters' do
      currency = Currency.new('U$D')
      expect(currency).not_to be_valid
      expect(currency.errors[:code]).to include('must be 3 uppercase letters')
    end
  end

  describe '#to_s' do
    it 'returns the currency code' do
      currency = build(:currency, code: 'EUR')
      expect(currency.to_s).to eq('EUR')
    end
  end

  describe '#==' do
    it 'returns true for currencies with the same code' do
      currency1 = Currency.new('USD')
      currency2 = Currency.new('USD')
      expect(currency1).to eq(currency2)
    end

    it 'returns false for currencies with different codes' do
      currency1 = Currency.new('USD')
      currency2 = Currency.new('EUR')
      expect(currency1).not_to eq(currency2)
    end
  end

  describe '#hash' do
    it 'allows currencies to be used in Sets' do
      currency1 = Currency.new('USD')
      currency2 = Currency.new('USD')
      currency3 = Currency.new('EUR')

      set = Set.new([currency1, currency2, currency3])
      expect(set.size).to eq(2)
    end
  end
end
