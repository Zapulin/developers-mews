# frozen_string_literal: true

# Fetches and parses exchange rates from Czech National Bank (CNB).
# Returns only rates defined by CNB for requested currencies (no calculated inverses).
# Uses caching to minimize API calls.
class CnbExchangeRateProviderService
  include ServiceResult

  class FetchError < StandardError; end
  class ParseError < StandardError; end

  BASE_CURRENCY = 'CZK'
  CACHE_KEY = 'cnb_exchange_rates'
  CACHE_DURATION = 10.minutes

  attr_reader :http_client

  # Dependency injection for flexibility/testing
  def initialize(http_client: nil)
    @http_client = http_client || Http::CnbClient.new
  end

  # Interactor pattern
  def self.call(currencies_param, http_client: nil)
    new(http_client: http_client).call(currencies_param)
  end

  # Expects either a string ("USD,EUR") or array of codes/Currency objects
  def call(currencies_param)
    currencies = parse_currencies(currencies_param)
    return success(fetch_all_rates) if currencies.blank?

    all_rates = fetch_all_rates
    filtered_rates = filter_rates(all_rates, currencies)

    success(filtered_rates)
  rescue FetchError, ParseError => e
    failure(e.message)
  rescue StandardError => e
    failure("Unexpected error: #{e.message}")
  end

  private

  # Normalize input
  def parse_currencies(param)
    case param
    when String
      param.split(',').map { |c| Currency.new(c.strip) }
    when Array
      param.map { |c| c.is_a?(Currency) ? c : Currency.new(c) }
    else
      []
    end
  end

  # Fetch all rates using the CNB client and caching
  def fetch_all_rates
    Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_DURATION) do
      result = http_client.fetch_daily

      raise FetchError, result.error unless result.success?

      parse_cnb_data(result.data)
    end
  rescue StandardError => e
    raise FetchError, "Failed to fetch exchange rates: #{e.message}"
  end

  # Filter rates based on requested currencies
  def filter_rates(rates, currencies)
    codes = currencies.map(&:code).map(&:upcase).to_set
    rates.select do |rate|
      codes.include?(rate.source_currency) ||
        (codes.include?(BASE_CURRENCY) && rate.source_currency != BASE_CURRENCY)
    end
  end

  # Parse CNB raw text
  def parse_cnb_data(data)
    lines = data.split("\n").map(&:strip).reject(&:empty?)
    raise ParseError, 'Empty CNB response' if lines.empty?

    date = parse_date(lines[0])
    lines[2..].map { |line| parse_rate_line(line, date) }.compact
  rescue StandardError => e
    raise ParseError, "Failed to parse CNB data: #{e.message}"
  end

  # Parse first line date
  def parse_date(line)
    match = line.match(/(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})/)
    raise ParseError, 'Invalid date format' unless match

    day = match[1].to_i
    month = match[2]
    year = match[3].to_i
    Date.parse("#{day} #{month} #{year}")
  rescue Date::Error => e
    raise ParseError, "Invalid date: #{e.message}"
  end

  # Parse each line to ExchangeRate object
  # rubocop:disable Metrics/MethodLength
  def parse_rate_line(line, date)
    parts = line.split('|').map(&:strip)
    return nil unless parts.size == 5

    ExchangeRate.new(
      source_currency: parts[3],
      target_currency: BASE_CURRENCY,
      amount: parts[2].to_i,
      rate: BigDecimal(parts[4].gsub(',', '.')),
      date: date
    )
  rescue StandardError => e
    Rails.logger.warn("Failed to parse CNB rate line: '#{line}' - #{e.message}")
    nil
  end
  # rubocop:enable Metrics/MethodLength
end
