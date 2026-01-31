# frozen_string_literal: true

# Provides value object behavior for non-database models with attributes and validations.
module ValueObject
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Model
    include ActiveModel::Attributes
  end
end
