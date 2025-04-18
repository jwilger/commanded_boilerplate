defmodule Commanded.Boilerplate.QueryTestModules do
  # Mock schema for our test queries
  defmodule TestProjection do
    use Ecto.Schema

    schema "test_projections" do
      field(:name, :string)
      field(:value, :integer)
    end
  end

  # Mock repo that doesn't hit the database
  defmodule MockRepo do
    def all(query, _opts) do
      send(self(), {:repo_called, :all, query})
      [%TestProjection{name: "test", value: 123}]
    end

    def one(query, _opts) do
      send(self(), {:repo_called, :one, query})
      %TestProjection{name: "test", value: 123}
    end

    def with_auth_subject(auth_subject, fun) do
      send(self(), {:with_auth_subject, auth_subject})
      {:ok, fun.()}
    end
  end

  # Test query with :all repo function
  defmodule TestAllQuery do
    use Commanded.Boilerplate.Query, repo: MockRepo, repo_fn: :all

    inputs do
      field(:name, :string)
    end

    validates(:name, string: true)

    def to_query(query) do
      import Ecto.Query
      from(t in TestProjection, where: t.name == ^query.name, select: t)
    end
  end

  # Test query with :one repo function
  defmodule TestOneQuery do
    use Commanded.Boilerplate.Query, repo: MockRepo, repo_fn: :one

    inputs do
      field(:id, :integer)
    end

    validates(:id, number: [greater_than: 0])

    def to_query(query) do
      import Ecto.Query
      from(t in TestProjection, where: t.value == ^query.id, select: t)
    end
  end

  # Test query with no inputs
  defmodule TestEmptyQuery do
    use Commanded.Boilerplate.Query, repo: MockRepo, repo_fn: :all

    inputs(:none)

    def to_query(_query) do
      import Ecto.Query
      from(t in TestProjection, select: t)
    end
  end

  # Test query with handle_result callback
  defmodule TestQueryWithResultHandler do
    use Commanded.Boilerplate.Query, repo: MockRepo, repo_fn: :all

    inputs do
      field(:name, :string)
    end

    validates(:name, string: true)

    def to_query(query) do
      import Ecto.Query
      from(t in TestProjection, where: t.name == ^query.name, select: t)
    end

    # This callback should be called by execute/1 to allow
    # transforming the result before returning it
    def handle_result({:ok, results}, query) do
      {:ok, %{
        original_results: results,
        transformed: true,
        query_name: query.name
      }}
    end

    def handle_result({:error, reason}, _query) do
      {:error, {:enhanced_error, reason}}
    end
  end
end
