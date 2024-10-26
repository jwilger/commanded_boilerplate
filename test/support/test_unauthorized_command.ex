defmodule Commanded.Boilerplate.TestUnauthorizedCommand do
  @moduledoc """
  This command is used as a stub in our tests.
  """

  use Commanded.Boilerplate.Command, identifier: :id

  inputs do
    field(:id, String.t())
  end

  aggregate do
    field(:id, String.t())
  end

  @impl Commanded.Boilerplate.Command
  def authorize(%__MODULE__{}), do: {:error, :unauthorized}

  @impl Commanded.Boilerplate.Command
  def handle(_aggregate, %__MODULE__{}), do: :ok
end
