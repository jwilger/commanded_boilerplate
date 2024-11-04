defmodule Commanded.Boilerplate.TestCommand do
  @moduledoc """
  This command is used as a stub in our tests.
  """

  alias Commanded.Boilerplate.TestAggregateCreated

  use Commanded.Boilerplate.Command, identifier: :id

  inputs do
    field(:id, binary())
    field(:some_required_key, String.t())
    field(:error_in_handle, boolean(), default: false)
  end

  aggregate do
    field(:id, binary())

    @impl Commanded.Boilerplate.Aggregate
    def apply(aggregate, %TestAggregateCreated{} = _event) do
      aggregate
    end
  end

  @impl Commanded.Boilerplate.Command
  def handle(_aggregate, %__MODULE__{error_in_handle: true}),
    do: {:error, {:command_handler_error, "There was an error handling the command"}}

  def handle(_aggregate, command) do
    {:ok, %TestAggregateCreated{id: command.id}}
  end

  @impl Commanded.Boilerplate.Command
  def authorize(%__MODULE__{}), do: :ok
end
