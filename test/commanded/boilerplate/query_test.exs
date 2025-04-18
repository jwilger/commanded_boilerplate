defmodule Commanded.Boilerplate.QueryTest do
  use Commanded.Boilerplate.TestCase

  alias Commanded.Boilerplate.AuthSubject

  alias Commanded.Boilerplate.QueryTestModules.{
    MockRepo,
    TestAllQuery,
    TestOneQuery,
    TestProjection,
    TestEmptyQuery,
    TestQueryWithResultHandler
  }

  setup do
    # Replace the application environment for tests
    Application.put_env(:commanded_boilerplate, :read_only_repo, MockRepo)

    on_exit(fn ->
      Application.delete_env(:commanded_boilerplate, :read_only_repo)
    end)

    :ok
  end

  describe "inputs" do
    test "defines struct fields from inputs" do
      query = %TestAllQuery{auth_subject: AuthSubject.system_user(), name: "test"}
      assert query.name == "test"
    end

    test "includes auth_subject by default" do
      query = %TestAllQuery{auth_subject: AuthSubject.system_user(), name: "test"}
      assert %AuthSubject{source: "SYSTEM", id: "SYSTEM"} = query.auth_subject
    end

    test "inputs :none still includes auth_subject" do
      query = %TestEmptyQuery{auth_subject: AuthSubject.system_user()}
      assert %AuthSubject{source: "SYSTEM", id: "SYSTEM"} = query.auth_subject
    end
  end

  describe "validation" do
    test "validates inputs successfully" do
      query = %TestAllQuery{auth_subject: AuthSubject.system_user(), name: "test"}
      {:ok, validated_query} = Commanded.Boilerplate.Query.QueryOps.validate(query)
      assert validated_query == query
    end

    test "returns error on invalid data" do
      query = %TestAllQuery{auth_subject: AuthSubject.system_user(), name: 123}
      {:error, {:invalid_query, error}} = Commanded.Boilerplate.Query.QueryOps.validate(query)
      # Extract errors from ValidationError struct
      errors = error.errors
      assert Enum.any?(errors, fn {field, _} -> field == :name end)
    end

    test "validates numeric constraints" do
      query = %TestOneQuery{auth_subject: AuthSubject.system_user(), id: 0}
      {:error, {:invalid_query, error}} = Commanded.Boilerplate.Query.QueryOps.validate(query)
      # Extract errors from ValidationError struct
      errors = error.errors
      assert Enum.any?(errors, fn {field, _} -> field == :id end)
    end
  end

  describe "to_query" do
    test "implements Ecto.Queryable protocol" do
      query = %TestAllQuery{auth_subject: AuthSubject.system_user(), name: "test"}
      ecto_query = Ecto.Queryable.to_query(query)
      assert is_struct(ecto_query, Ecto.Query)
    end
  end

  describe "repo_fn" do
    test "uses :all function for all repo_fn" do
      query = %TestAllQuery{auth_subject: AuthSubject.system_user(), name: "test"}
      result = Commanded.Boilerplate.Query.QueryOps.repo_fn(query)
      assert is_list(result)
      assert [%TestProjection{}] = result
      assert_received {:repo_called, :all, _query}
    end

    test "uses :one function for one repo_fn" do
      query = %TestOneQuery{auth_subject: AuthSubject.system_user(), id: 123}
      result = Commanded.Boilerplate.Query.QueryOps.repo_fn(query)
      assert %TestProjection{} = result
      assert_received {:repo_called, :one, _query}
    end
  end

  describe "execute" do
    test "executes query with auth_subject" do
      query = %TestAllQuery{auth_subject: AuthSubject.system_user(), name: "test"}
      {:ok, results} = Commanded.Boilerplate.Query.execute(query)

      assert [%TestProjection{name: "test", value: 123}] = results
      assert_received {:with_auth_subject, %AuthSubject{source: "SYSTEM", id: "SYSTEM"}}
    end

    test "converts auth_subject during execution" do
      # Use system_user() first and convert to string to ensure protocol is implemented
      system_user = AuthSubject.system_user()

      query = %TestAllQuery{
        auth_subject: %{
          source: system_user.source,
          id: system_user.id,
          permissions: ["superuser"]
        },
        name: "test"
      }

      {:ok, _results} = Commanded.Boilerplate.Query.execute(query)

      assert_received {:with_auth_subject, %AuthSubject{source: "SYSTEM", id: "SYSTEM"}}
    end

    test "returns validation errors" do
      query = %TestAllQuery{auth_subject: AuthSubject.system_user(), name: 123}
      {:error, {:invalid_query, _errors}} = Commanded.Boilerplate.Query.execute(query)
    end
  end

  describe "execute with handle_result/2 callback" do
    test "should modify successful results when handle_result/2 is implemented" do
      query = %TestQueryWithResultHandler{
        auth_subject: AuthSubject.system_user(),
        name: "test"
      }

      expected = {:ok, %{
        original_results: [%TestProjection{name: "test", value: 123}],
        transformed: true,
        query_name: "test"
      }}

      assert expected == Commanded.Boilerplate.Query.execute(query)
    end
  end
end
