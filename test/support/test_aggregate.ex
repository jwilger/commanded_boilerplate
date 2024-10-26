defmodule Commanded.Boilerplate.TestAggregate do
  @moduledoc """
  This aggregate is used as a stub in our tests
  """

  alias Commanded.Boilerplate.TestAggregateCreated

  @type t() :: %__MODULE__{}

  @derive Jason.Encoder
  defstruct [:id]

  @spec apply(t(), struct()) :: t()
  def apply(aggregate, %TestAggregateCreated{id: id}) do
    %{aggregate | id: id}
  end
end
