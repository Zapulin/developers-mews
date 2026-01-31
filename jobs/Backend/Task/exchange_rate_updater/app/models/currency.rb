# frozen_string_literal: true

# Represents a currency using ISO 4217 3-letter codes (e.g., USD, EUR, CZK)
# This is a value object - immutable and compared by value.
class Currency
  include ValueObject

  attribute :code, :string

  validates :code, presence: true,
                   length: { is: 3 },
                   format: { with: /\A[A-Z]{3}\z/, message: 'must be 3 uppercase letters' }

  def initialize(code)
    super(code: code&.upcase)
  end

  def to_s
    code
  end

  def ==(other)
    other.is_a?(Currency) && code == other.code
  end

  alias eql? ==

  def hash
    code.hash
  end
end
