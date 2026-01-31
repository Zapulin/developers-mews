# frozen_string_literal: true

module Http
  # Immutable result object for HTTP operations.
  # Returns success/failure state with data or error details.
  Result = Data.define(:success, :data, :error, :error_type) do
    def success? = success
    def failure? = !success
  end
end
