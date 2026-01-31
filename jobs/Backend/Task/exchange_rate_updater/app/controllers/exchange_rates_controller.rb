# frozen_string_literal: true

# Web controller for displaying exchange rates in HTML format.
# Provides a user-friendly interface for viewing and filtering CNB exchange rates.
class ExchangeRatesController < ApplicationController
  def index
    result = CnbExchangeRateProviderService.call(params[:currencies])

    if result.success?
      @rates = result.result
      @all_currencies = extract_all_currencies(@rates)
    else
      @error = result.errors.join(', ')
      @rates = []
      @all_currencies = []
    end
  end

  private

  def extract_all_currencies(rates)
    rates.map(&:source_currency).uniq.sort
  end
end
