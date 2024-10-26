Mox.defmock(Commanded.Boilerplate.MockRepo, for: Ecto.Repo)

defmodule Commanded.Boilerplate.TestQuery do
  @moduledoc """
  Test stub Query implementation for query using the `all/2` repo function
  """

  alias Commanded.Boilerplate.TestProjection

  use Commanded.Boilerplate.Query, repo: Commanded.Boilerplate.MockRepo, repo_fn: :all

  @type foo() :: String.t()

  inputs do
    field(:foo, String.t())
  end

  validates(:foo, string: true)

  @impl Commanded.Boilerplate.Query
  def to_query(_query) do
    from(t in TestProjection, select: t)
  end
end

defmodule Commanded.Boilerplate.TestOneQuery do
  @moduledoc """
  Test stub Query implementation for query using the `one/2` repo function
  """

  alias Commanded.Boilerplate.TestProjection

  use Commanded.Boilerplate.Query, repo: Commanded.Boilerplate.MockRepo, repo_fn: :one

  inputs do
    field(:foo, String.t())
  end

  @impl Commanded.Boilerplate.Query
  def to_query(_query) do
    from(t in TestProjection, select: t)
  end
end
