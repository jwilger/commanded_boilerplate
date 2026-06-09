defmodule CommandedAggregateless.Aggregate do
  @moduledoc false

  @callback apply(struct(), struct()) :: struct()
end
