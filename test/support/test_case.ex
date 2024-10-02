defmodule Commanded.Boilerplate.TestCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use ExUnitProperties
    end
  end
end
