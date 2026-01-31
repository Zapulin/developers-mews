# frozen_string_literal: true

module Http
  # HTTP client for Czech National Bank (CNB) exchange rate API.
  # Fetches daily exchange rate data with built-in retry logic and timeout handling.
  class CnbClient < Client
    BASE_URL = 'https://www.cnb.cz'
    DAILY_PATH = '/en/financial-markets/foreign-exchange-market/central-bank-exchange-rate-fixing/central-bank-exchange-rate-fixing/daily.txt'

    def initialize
      super(base_url: BASE_URL)
    end

    def fetch_daily
      get(DAILY_PATH)
    end
  end
end
