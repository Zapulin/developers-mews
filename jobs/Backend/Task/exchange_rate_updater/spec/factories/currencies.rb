# frozen_string_literal: true

FactoryBot.define do
  factory :currency do
    skip_create

    initialize_with { new(code) }

    code { 'USD' }

    trait :usd do
      code { 'USD' }
    end

    trait :eur do
      code { 'EUR' }
    end

    trait :gbp do
      code { 'GBP' }
    end

    trait :czk do
      code { 'CZK' }
    end

    trait :jpy do
      code { 'JPY' }
    end
  end
end
