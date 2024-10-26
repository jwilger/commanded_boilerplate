defmodule Commanded.Boilerplate.TestProjection do
  @moduledoc """
  Test stub Projection implementation
  """

  use TypedEctoSchema

  typed_schema "test_projection" do
    field(:foo, :string)
  end
end
