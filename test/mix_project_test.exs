defmodule CommandedBoilerplate.MixProjectTest do
  use ExUnit.Case, async: true

  test "targets the current Elixir toolchain" do
    assert Mix.Project.config()[:elixir] == "~> 1.20"
  end

  test "faker is not overridden with a repository-local compile script" do
    faker_dep =
      Mix.Project.config()
      |> Keyword.fetch!(:deps)
      |> Enum.find(fn
        {:faker, _requirement, _opts} -> true
        _ -> false
      end)

    assert is_nil(faker_dep)
  end
end
