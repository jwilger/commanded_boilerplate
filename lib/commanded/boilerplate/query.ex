defmodule Commanded.Boilerplate.Query do
  @moduledoc """
  Provides common functionality for the execution of queries against the read store

  Example:

      defmodule Commanded.Boilerplate.TestQuery do
        use Commanded.Boilerplate.Query, repo: Commanded.Boilerplate.ReadOnlyRepo, repo_fn: :all

        inputs do
          field :foo, :string
        end

        validates(:foo, string: true)

        def to_query(_query) do
          from t in TestProjection, select: t
        end
      end
  """

  alias Commanded.Boilerplate.AuthSubject

  @type t() :: __MODULE__.QueryOps.t()

  @type repo_fn_result() ::
          term() | nil | [Ecto.Schema.t() | term()] | boolean() | Ecto.Schema.t() | Enum.t()

  @type validation_error() :: {:invalid_query, keyword(String.t())}
  @type result() :: Commanded.Boilerplate.result(repo_fn_result(), validation_error())
  @type result(type) :: Commanded.Boilerplate.result(type, validation_error())
  @type error() :: validation_error()

  @callback to_query(t()) :: Ecto.Query.t()

  @doc """
  Callback that allows a query to manipulate the results before they are returned.

  A default implementation that simply returns the result unchanged is provided when
  using `use Commanded.Boilerplate.Query`.
  """
  @callback handle_result(result(), t()) :: result()

  defprotocol QueryOps do
    @moduledoc """
    Defines common functionality for the execution of queries against the read store

    While the `Commanded.Boilerplate.Query` module can be used to define query modules, you can
    also use any data type for which you have provided an implementation of this
    protocol.
    """

    alias Commanded.Boilerplate.Query

    @doc """
    Performs validation on the query prior to execution.
    """
    @spec validate(t()) :: Commanded.Boilerplate.result(t(), Query.validation_error())
    def validate(query)

    @doc """
    This must dispatch the execution of the query against the read store.
    """
    @spec repo_fn(t()) :: Query.repo_fn_result()
    def repo_fn(query)
  end

  @doc """
  Sets up a query module for use with the `Commanded.Boilerplate.Query.QueryOps` protocol.

  See module documentation for an example.
  """
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(opts \\ []) do
    repo_fn = Keyword.fetch!(opts, :repo_fn)
    repo = Keyword.get(opts, :repo, Commanded.Boilerplate.ReadOnlyRepo)

    quote location: :keep do
      require Commanded.Boilerplate.Query

      use Commanded.Boilerplate.StructValidation

      @behaviour Commanded.Boilerplate.Query

      import Commanded.Boilerplate.Query, only: [inputs: 1]
      import Ecto.Query, only: [from: 2]

      defimpl Ecto.Queryable do
        def to_query(query), do: __impl__(:for).to_query(query)
      end

      defimpl Commanded.Boilerplate.Query.QueryOps do
        def validate(query) when is_struct(query) do
          case query.__struct__.validate(query) do
            {:error, errors} -> {:error, {:invalid_query, errors}}
            {:ok, query} -> {:ok, query}
          end
        end

        case unquote(repo_fn) do
          :all ->
            def repo_fn(query), do: unquote(repo).all(query, [])

          :one ->
            def repo_fn(query), do: unquote(repo).one(query, [])
        end
      end

      # Default implementation of handle_result/2
      def handle_result(result, _query), do: result

      defoverridable handle_result: 2
    end
  end

  @doc """
  Defines the inputs to the query.

  See module documentation for an example.
  """
  @spec inputs(:none | [do: Macro.t()]) :: Macro.t()
  defmacro inputs(:none) do
    fields =
      quote location: :keep do
        field(:auth_subject, AuthSubject.Conversion.t(), enforce: true)
      end

    ast = TypedStruct.__typedstruct__(fields, [])

    quote location: :keep do
      # Create a lexical scope.
      (fn -> unquote(ast) end).()
    end
  end

  defmacro inputs(do: block) do
    fields =
      quote location: :keep do
        field(:auth_subject, AuthSubject.Conversion.t(), enforce: true)
        unquote(block)
      end

    ast = TypedStruct.__typedstruct__(fields, [])

    quote location: :keep do
      # Create a lexical scope.
      (fn -> unquote(ast) end).()
    end
  end

  @doc """
  Executes the query against the read store.
  """
  @spec execute(QueryOps.t()) :: result()
  def execute(query) do
    query = %{query | auth_subject: AuthSubject.Conversion.convert(query.auth_subject)}

    with {:ok, query} <- QueryOps.validate(query) do
      # This case statement is here, because we want to unwrap the result of the transaction
      case repo().with_auth_subject(query.auth_subject, fn ->
             run_query(query)
           end) do
        {:ok, result} ->
          query.__struct__.handle_result(result, query)
        error -> error
      end
    end
  end

  defp run_query(query) do
    case QueryOps.repo_fn(query) do
      {:error, error} -> {:error, error}
      result -> {:ok, result}
    end
  end

  defp repo do
    Application.get_env(:commanded_boilerplate, :read_only_repo)
  end
end
