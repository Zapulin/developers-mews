# frozen_string_literal: true

# Represents an exchange rate between two currencies at a specific date
# Handles multi-unit rates (e.g., 100 JPY = 17.5 CZK)
class ExchangeRate
  include ValueObject

  attribute :source_currency, :string
  attribute :target_currency, :string
  attribute :rate, :decimal
  attribute :amount, :integer, default: 1
  attribute :date, :date

  validates :source_currency, :target_currency, :rate, :amount, :date, presence: true
  validates :rate, numericality: { greater_than: 0 }
  validates :amount, numericality: { greater_than: 0, only_integer: true }

  def initialize(attributes = {})
    super
    self.source_currency = source_currency.to_s.upcase if source_currency
    self.target_currency = target_currency.to_s.upcase if target_currency
  end

  # Returns the effective exchange rate (normalized to amount = 1)
  def normalized_rate
    rate / amount
  end

  def to_s
    "#{amount} #{source_currency} = #{rate} #{target_currency} (#{date})"
  end

  def as_json(_options = {})
    raise 'Cannot serialize invalid ExchangeRate' unless valid?

    {
      source_currency: source_currency,
      target_currency: target_currency,
      rate: rate.to_f,
      amount: amount,
      normalized_rate: normalized_rate.to_f,
      date: date.iso8601
    }
  end
end
