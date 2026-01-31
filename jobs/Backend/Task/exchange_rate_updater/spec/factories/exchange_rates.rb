# frozen_string_literal: true

FactoryBot.define do
  factory :exchange_rate do
    skip_create
    initialize_with { new(attributes) }

    source_currency { 'USD' }
    target_currency { 'CZK' }
    rate { 23.456 }
    amount { 1 }
    date { Date.today }

    trait :eur do
      source_currency { 'EUR' }
      rate { 25.123 }
    end

    trait :jpy do
      source_currency { 'JPY' }
      rate { 17.567 }
      amount { 100 }
    end

    trait :yesterday do
      date { Date.yesterday }
    end

    trait :invalid do
      rate { nil }
    end
  end
end
