defmodule Commanded.Boilerplate.StructValidation do
  @moduledoc """
  Provides a default `validate/1` function for structs using Vex
  """

  @type validation_result(struct_type) ::
          Commanded.Boilerplate.result(struct_type, __MODULE__.ValidationError.t())
  @type struct(type) :: %{:__struct__ => type, optional(atom()) => any()}

  defmodule ValidationError do
    @type errors() ::
            list(
              {attribute :: atom(),
               list({validation_type :: atom(), validation_message :: String.t()})}
            )
    @type t() :: %__MODULE__{errors: errors()}

    defexception [:errors]

    @impl Exception
    def message(%__MODULE__{} = exception) do
      "Validation failed with the following error(s):\n" <>
        Enum.map_join(exception.errors, "\n", fn {field, failed_validations} ->
          "- #{field}:\n" <>
            Enum.map_join(failed_validations, "\n", fn {_validation, message} ->
              "  - #{message}"
            end)
        end)
    end
  end

  defmacro __using__(_opts \\ []) do
    struct_validation = __MODULE__

    quote do
      use Vex.Struct

      defdelegate validate(struct), to: unquote(struct_validation)
      defoverridable(validate: 1)

      @doc """
      Builds and validates a new `#{__MODULE__ |> to_string() |> String.replace_prefix("Elixir.", "")}`
      with the given attributes and validates it using `Vex`.

      Returns `{:ok, struct()}` if the struct is valid, otherwise `{:error,
      ValidationError.t()}`.
      """
      def new(attrs), do: unquote(struct_validation).new(attrs, __MODULE__)
      defoverridable(new: 1)
    end
  end

  @doc """
  Builds a new struct with the given attributes and type then validates it using `Vex`

  Returns `{:ok, struct}` if the struct is valid, otherwise `{:error, errors}`
  where errors is a keyword list with keys being the invalid fields and the
  values being keyword lists of the validation errors for that field.
  """
  # Credo suggests using a pipeline instead of a nested function call *for a typespec* 🤦
  # credo:disable-for-next-line
  @spec new(Enum.t() | struct(type), type) ::
          Commanded.Boilerplate.result(struct(type), ValidationError.t())
        when type: atom()
  def new(attrs, struct_type) when is_struct(attrs) do
    attrs
    |> Map.from_struct()
    |> new(struct_type)
  end

  def new(attrs, struct_type) do
    attrs
    |> Enum.into(%{})
    |> then(&struct(struct_type, &1))
    |> validate()
  end

  @doc """
  Validates the given struct using Vex

  Returns `{:ok, struct}` if the struct is valid, otherwise `{:error, errors}`
  where errors is a keyword list with keys being the invalid fields and the
  values being keyword lists of the validation errors for that field.
  """
  @spec validate(struct_type) :: validation_result(struct_type) when struct_type: struct()
  def validate(data) do
    case Vex.validate(data) do
      {:ok, data} -> {:ok, data}
      {:error, errors} -> {:error, ValidationError.exception(errors: restructure_errors(errors))}
    end
  end

  defp restructure_errors(errors) when is_list(errors) do
    Enum.map(errors, fn {:error, field, validator, message} ->
      {field, [{validator, message}]}
    end)
  end
end
