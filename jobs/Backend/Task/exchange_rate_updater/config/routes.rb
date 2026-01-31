# frozen_string_literal: true

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  # Web UI
  root 'exchange_rates#index'
  resources :exchange_rates, only: [:index]

  # REST API
  namespace :api do
    namespace :v1 do
      resources :exchange_rates, only: [:index]
    end
  end

  # Health check
  get 'up' => 'rails/health#show', as: :rails_health_check
end
