defmodule Commanded.Boilerplate.Command.ValidationMiddleware do
  @moduledoc """
  Middleware for validating commands.
  """

  @behaviour Commanded.Middleware

  alias Commanded.Middleware.Pipeline
  alias Commanded.Boilerplate.Command.CommandProtocol

  import Pipeline

  @impl Commanded.Middleware
  def before_dispatch(%Pipeline{command: command} = pipeline) do
    case CommandProtocol.validate(command) do
      {:ok, _command} ->
        pipeline

      {:error, errors} ->
        pipeline |> respond({:error, :invalid_command, errors}) |> halt()
    end
  end

  @impl Commanded.Middleware
  def after_dispatch(pipeline) do
    pipeline
  end

  @impl Commanded.Middleware
  def after_failure(pipeline) do
    pipeline
  end
end
