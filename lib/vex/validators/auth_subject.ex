defmodule Vex.Validators.AuthSubject do
  @moduledoc """
  Validates that the provided value implements the
  `CommandedAggregateless.AuthSubject.Conversion` protocol
  """

  alias CommandedAggregateless.AuthSubject

  use Vex.Validator

  @message_fields [value: "The bad value"]

  def validate(value, options \\ []) do
    if AuthSubject.auth_subject?(value) do
      :ok
    else
      {:error,
       message(
         options,
         "must implement the CommandedAggregateless.AuthSubject.Conversion protocol",
         value: value
       )}
    end
  end
end
