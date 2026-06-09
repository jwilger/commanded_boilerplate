Mox.defmock(CommandedAggregateless.MockRepo, for: Ecto.Repo)

defmodule CommandedAggregateless.TestQuery do
  @moduledoc """
  Test stub Query implementation for query using the `all/2` repo function
  """

  alias CommandedAggregateless.TestProjection

  use CommandedAggregateless.Query, repo: CommandedAggregateless.MockRepo, repo_fn: :all

  @type foo() :: String.t()

  inputs do
    field(:foo, String.t())
  end

  validates(:foo, string: true)

  @impl CommandedAggregateless.Query
  def to_query(_query) do
    from(t in TestProjection, select: t)
  end
end

defmodule CommandedAggregateless.TestOneQuery do
  @moduledoc """
  Test stub Query implementation for query using the `one/2` repo function
  """

  alias CommandedAggregateless.TestProjection

  use CommandedAggregateless.Query, repo: CommandedAggregateless.MockRepo, repo_fn: :one

  inputs do
    field(:foo, String.t())
  end

  @impl CommandedAggregateless.Query
  def to_query(_query) do
    from(t in TestProjection, select: t)
  end
end
