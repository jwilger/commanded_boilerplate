defmodule Vex.Validators.String do
  @moduledoc """
  A string validator that allows nil values and requires non-blank strings

  Intended to be used with `Vex` to validate string fields.
  """

  use Vex.Validator

  @impl Vex.Validator.Behaviour
  def validate(data, options \\ [])
  def validate(data, true), do: validate(data)

  def validate(data, options) do
    options = Enum.into(options, %{})

    {:cont, data}
    |> validate_type(options)
    |> validate_presence(options)
    |> validate_length(options)
    |> validate_format(options)
    |> build_return_value(options)
  end

  defp validate_type({:cont, nil}, _options), do: {:cont, nil}

  defp validate_type({:cont, data}, _options) when is_binary(data) do
    if String.valid?(data) do
      {:cont, data}
    else
      {:stop, {:error, :not_a_string}}
    end
  end

  defp validate_type({:cont, _data}, _options), do: {:stop, {:error, :not_a_string}}

  defp validate_presence({:stop, result}, _options), do: {:stop, result}

  defp validate_presence({:cont, nil}, options) do
    allow_nil = Map.get(options, :allow_nil, false)

    if allow_nil do
      {:stop, :ok}
    else
      {:stop, {:error, :not_a_string}}
    end
  end

  defp validate_presence({:cont, data}, options) do
    allow_blank = Map.get(options, :allow_blank, false)

    cond do
      data !== to_string(data) ->
        {:stop, {:error, :not_a_string}}

      allow_blank ->
        {:cont, data}

      data |> String.trim() |> String.length() > 0 ->
        {:cont, data}

      true ->
        {:stop, {:error, :blank_string}}
    end
  end

  defp validate_length({:stop, result}, _options), do: {:stop, result}

  defp validate_length({:cont, data}, options) do
    max_length = Map.get(options, :max_length, nil)

    if is_nil(max_length) do
      {:cont, data}
    else
      if String.length(data) <= max_length do
        {:cont, data}
      else
        {:stop, {:error, :too_long}}
      end
    end
  end

  defp validate_format({:stop, result}, _options), do: {:stop, result}

  defp validate_format({:cont, data}, options) do
    format = Map.get(options, :format, nil)

    if is_nil(format) do
      {:cont, data}
    else
      if Regex.match?(format, data) do
        {:cont, data}
      else
        {:stop, {:error, :invalid_format}}
      end
    end
  end

  defp build_return_value({:stop, :ok}, _options), do: :ok
  defp build_return_value({:cont, _data}, _options), do: :ok

  defp build_return_value({:stop, {:error, type}}, %{} = options) do
    if message = Map.get(options, :message, nil) do
      {:error, message}
    else
      build_return_value_for_error_type({:stop, {:error, type}}, options)
    end
  end

  defp build_return_value_for_error_type({:stop, {:error, :not_a_string}}, options) do
    allow_nil = Map.get(options, :allow_nil, false)
    allow_blank = Map.get(options, :allow_blank, false)

    message =
      cond do
        allow_nil && allow_blank ->
          "must be a string if provided"

        allow_nil ->
          "must be a non-blank string if provided"

        allow_blank ->
          "must be a string"

        true ->
          "must be a non-blank string"
      end

    {:error, message}
  end

  defp build_return_value_for_error_type({:stop, {:error, :blank_string}}, options) do
    allow_nil = Map.get(options, :allow_nil, false)

    message =
      if allow_nil do
        "must be a non-blank string if provided"
      else
        "must be a non-blank string"
      end

    {:error, message}
  end

  defp build_return_value_for_error_type({:stop, {:error, :too_long}}, options) do
    max_length = Map.fetch!(options, :max_length)
    message = "must be at most #{max_length} characters"
    {:error, message}
  end

  defp build_return_value_for_error_type({:stop, {:error, :invalid_format}}, _options) do
    message = "must have the correct format"
    {:error, message}
  end
end
