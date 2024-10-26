defmodule Commanded.Boilerplate.Command do
  @moduledoc ~S"""
  Provides a basic command module setup to reduce boilerplate

  Example:

      defmodule Commanded.Boilerplate.TestCommand do
        use Commanded.Boilerplate.Command,
          identifier: :id,
          prefix: "test",
          required_permission: "manage_tests"

        alias Commanded.Boilerplate.TestAggregateCreated

        inputs do
          field :id, binary()

          field :some_required_key, binary()
          field :error_in_handle, boolean()
        end

        validates(:some_required_key, string: true)

        aggregate do
          field :id, binary()

          apply_event TestAggregateCreated do
            %{aggregate | id: event.id}
          end
        end

        def handle(_aggregate, %__MODULE__{error_in_handle: true}),
          do: {:error, {:command_handler_error, "There was an error handling the command"}}

        def handle(%{id: nil}, command) do
          {:ok, %TestAggregateCreated{id: command.id}}
        end

        def handle(_aggregate, command) do
          {:error, {:aggregate_exists, "Aggregate #{command.id} already exists."}}
        end
      end
  """

  alias Commanded.Boilerplate.StructValidation.ValidationError

  require Logger

  @type event :: struct()

  @type validation_result() ::
          Commanded.Boilerplate.result({:ok, __MODULE__.CommandProtocol.t()}, ValidationError.t())

  @type authorization_result() :: Commanded.Boilerplate.result(:unauthorized)

  @type execution_error :: {atom(), String.t() | nil}
  @type execution_success :: list(event())
  @type execution_result ::
          Commanded.Boilerplate.result(execution_success(), execution_error())
          | Commanded.Boilerplate.result(execution_error())

  @doc """
  Validates the data in a command

  Commands all use the `Commanded.Boilerplate.StructValidation` module to
  validate their data by default, but you can override this behavior by
  implementing the `validate/1` function in your command module.
  """
  @callback validate(__MODULE__.CommandProtocol.t()) :: validation_result()

  @doc """
  Authorizes a command

  Must return `:ok` if the command is authorized, or `{:error, :unauthorized}`
  if it is not.

  The default implementation checks if the `auth_subject` has the required
  permission as specified when calling `use Commanded.Boilerplate.Command`.
  """
  @callback authorize(__MODULE__.CommandProtocol.t()) :: authorization_result()

  @doc """
  Handles a command

  Passed the current state of the aggegate and the command to be handled. May return:

  - `{:ok, events}` - to indicate the command was successful and return a list of events
  - `{:error, error}` - to indicate the command failed with an error
  - `:ok` - to indicate the command was successful with no events
  """
  @callback handle(struct(), __MODULE__.CommandProtocol.t()) :: execution_result()

  defprotocol CommandProtocol do
    @moduledoc """
    Protocol to be implemented by all command modules
    """

    alias Commanded.Boilerplate.Command

    @doc """
    Validates the data in a command

    See `Commanded.Boilerplate.Command.ValidationMiddleware` for more information.
    """
    @spec validate(t()) :: Command.validation_result()
    def validate(command)

    @doc """
    Authorizes a command

    See `Commanded.Boilerplate.Command.AuthorizationMiddleware` for more information.
    """
    @spec authorize(t()) :: Command.authorization_result()
    def authorize(command)
  end

  @doc """
  Provides basic setup of a command module to reduce boilerplate
  """
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(opts \\ []) do
    {required_permission, opts} = Keyword.pop(opts, :required_permission)

    quote do
      alias Commanded.Boilerplate.AuthSubject
      require Commanded.Boilerplate.Command

      use Commanded.Boilerplate.StructValidation
      use Commanded.Boilerplate.Command.Router

      @dispatch_opts unquote(opts)
      @required_permission unquote(required_permission)

      register_command(__MODULE__, @dispatch_opts)

      @behaviour Commanded.Boilerplate.Command

      import Commanded.Boilerplate.Command

      @impl Commanded.Boilerplate.Command
      defdelegate validate(command), to: Commanded.Boilerplate.StructValidation
      defoverridable(validate: 1)

      @impl Commanded.Boilerplate.Command
      def authorize(command) do
        if AuthSubject.has_permission?(
             command.auth_subject,
             @required_permission
           ) do
          :ok
        else
          {:error, :unauthorized}
        end
      end

      defoverridable(authorize: 1)

      @impl Commanded.Boilerplate.Command
      def handle(_aggregate, _command),
        do: {:error, {:not_implemented, "handle/2 not implemented in #{__MODULE__}"}}

      defoverridable(handle: 2)

      defimpl Commanded.Boilerplate.Command.CommandProtocol do
        @impl Commanded.Boilerplate.Command.CommandProtocol
        def validate(command) do
          __impl__(:for).validate(command)
        end

        @impl Commanded.Boilerplate.Command.CommandProtocol
        def authorize(command) do
          __impl__(:for).authorize(command)
        end
      end
    end
  end

  @doc """
  Defines the inputs to the command

  See module documentation for an example.
  """
  @spec inputs(keyword(), do: Macro.t()) :: Macro.t()
  defmacro inputs(opts \\ [], do: block) do
    opts = opts |> Keyword.put_new(:enforce, true) |> Keyword.put_new(:opaque, true)

    fields =
      quote do
        field(:auth_subject, Commanded.Boilerplate.AuthSubject.Conversion.t(), enforce: true)
        unquote(block)
      end

    ast = TypedStruct.__typedstruct__(fields, opts)

    quote do
      alias Commanded.Boilerplate.AuthSubject
      # Create a lexical scope.
      (fn -> unquote(ast) end).()
    end
  end

  @doc """
  Defines the aggregate attributes for the command

  See module documentation for an example.
  """
  @spec aggregate(keyword(), do: Macro.t()) :: Macro.t()
  defmacro aggregate(opts \\ [], do: block) do
    ast = TypedStruct.__typedstruct__(block, opts)

    quote do
      defmodule Aggregate do
        @moduledoc false

        unquote(ast)

        def apply(aggregate, event) do
          Logger.debug(
            "Skipping application of event #{inspect(event.__struct__)} to aggregate #{inspect(aggregate.__struct__)}. Add an `apply/2` clause to handle this event."
          )

          aggregate
        end
      end
    end
  end
end
