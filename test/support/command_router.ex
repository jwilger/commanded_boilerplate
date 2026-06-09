defmodule CommandedAggregateless.Test.CommandRouter do
  @moduledoc """
  The command router used for our stub commands in tests
  """

  use Commanded.Commands.CompositeRouter

  router(CommandedAggregateless.TestCommand)
  router(CommandedAggregateless.TestUnauthorizedCommand)
end
