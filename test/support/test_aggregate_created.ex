defmodule Commanded.Boilerplate.TestAggregateCreated do
  @moduledoc """
  Used by tests to create a TestAggregate
  """

  use TypedStruct

  @derive Jason.Encoder
  typedstruct do
    field(:id, binary())
  end
end
