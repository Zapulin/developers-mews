# frozen_string_literal: true

# Provides a Result pattern for service objects with success/failure responses.
# Returns immutable Result objects with success?, failure?, result, and errors.
module ServiceResult
  Result = Data.define(:success, :result, :errors) do
    def success? = success
    def failure? = !success
  end

  def success(result = nil)
    Result.new(success: true, result: result, errors: [])
  end

  def failure(errors = [])
    Result.new(success: false, result: nil, errors: Array.wrap(errors))
  end
end
