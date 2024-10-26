defmodule Commanded.Boilerplate.Test.CommandRouter do
  @moduledoc """
  The command router used for our stub commands in tests
  """

  use Commanded.Commands.CompositeRouter

  router(Commanded.Boilerplate.TestCommand)
  router(Commanded.Boilerplate.TestUnauthorizedCommand)
end
