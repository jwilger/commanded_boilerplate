defmodule CommandedAggregateless.TestUnauthorizedCommand do
  @moduledoc """
  This command is used as a stub in our tests.
  """

  use CommandedAggregateless.Command, identifier: :id

  inputs do
    field(:id, String.t())
  end

  aggregate do
    field(:id, String.t())
  end

  @impl CommandedAggregateless.Command
  def authorize(%__MODULE__{}), do: {:error, :unauthorized}

  @impl CommandedAggregateless.Command
  def handle(_aggregate, %__MODULE__{}), do: :ok
end
