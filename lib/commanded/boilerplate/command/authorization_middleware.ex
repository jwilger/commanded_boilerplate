defmodule Commanded.Boilerplate.Command.AuthorizationMiddleware do
  @moduledoc """
  Middleware that authorizes commands.

  The command must have an `auth_subject` field that is a `Commanded.Boilerplate.AuthSubject`
  (or a value that can be converted to one).
  """

  @behaviour Commanded.Middleware

  alias Commanded.Boilerplate.AuthSubject
  alias Commanded.Middleware.Pipeline
  alias Commanded.Boilerplate.Command.CommandProtocol

  require Logger

  import Pipeline

  @impl Commanded.Middleware
  def before_dispatch(%Pipeline{command: command} = pipeline) do
    auth_subject = AuthSubject.Conversion.convert(command.auth_subject)
    command = %{command | auth_subject: auth_subject}

    case CommandProtocol.authorize(command) do
      :ok ->
        %{pipeline | command: command}

      {:error, :unauthorized} ->
        Logger.warning("Unauthorized command: #{inspect(command)}")
        pipeline |> respond({:error, :unauthorized_command}) |> halt()
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
