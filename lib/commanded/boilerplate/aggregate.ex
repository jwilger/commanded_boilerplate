defmodule Commanded.Boilerplate.Aggregate do
  @moduledoc false

  @callback apply(struct(), struct()) :: struct()
end
