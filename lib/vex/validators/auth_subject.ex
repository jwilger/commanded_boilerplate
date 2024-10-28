defmodule Vex.Validators.AuthSubject do
  @moduledoc """
  Validates that the provided value implements the
  `Commanded.Boilerplate.AuthSubject.Conversion` protocol
  """

  alias Commanded.Boilerplate.AuthSubject

  use Vex.Validator

  @message_fields [value: "The bad value"]

  @impl Vex.Validator.Behaviour
  def validate(value, options \\ []) do
    if AuthSubject.auth_subject?(value) do
      :ok
    else
      {:error,
       message(
         options,
         "must implement the Commanded.Boilerplate.AuthSubject.Conversion protocol",
         value: value
       )}
    end
  end
end
