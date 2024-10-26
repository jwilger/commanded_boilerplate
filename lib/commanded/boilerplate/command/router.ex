defmodule Commanded.Boilerplate.Command.Router do
  @moduledoc """
  Provides basic DSQL for registering commands with the
  Commanded.Commands.Router

  This sets up a consistent convention that dispatches commands to an
  aggregate-per-command.
  """

  @doc """
  Configure the module to be able to register commands
  """
  @spec __using__(any) :: Macro.t()
  defmacro __using__(_opts) do
    quote do
      use Commanded.Commands.Router

      import Commanded.Boilerplate.Command.Router

      middleware(Commanded.Boilerplate.Command.ValidationMiddleware)
      middleware(Commanded.Boilerplate.Command.AuthorizationMiddleware)
    end
  end

  @doc """
  Register a command with the Commanded.Commands.Router

  Options:
    - `:aggregate` - the aggregate module to dispatch the command to. Defaults
      to the command module's Aggregate module (e.g. MyCommand.Aggregate)
    - `:aggregate_identifier` - the aggregate identifier. This is a keyword
      list with `by` and `prefix` keys. Defaults to the value returned by the
      aggregate module's `identifier/0` function function.
    - `:lifespan` - the lifespan module to user with this command. Defaults to
      `Commanded.Boilerplate.Command.DefaultLifespan`
    - `:timeout` - the timeout for the command. Defaults to 5_000ms.

  Examples:
    ```
    register_command(MyCommand)

    register_command(
      MyCommand,
      aggregate: MyAggregate,
      aggregate_identifier: [by: :id, prefix: "my_aggregate"],
      lifespan: MyLifespan,
      timeout: 10_000
    )
    ```
  """
  @spec register_command(atom(), keyword()) :: Macro.t()
  defmacro register_command(command_module, opts \\ []) do
    quote generated: true, bind_quoted: [command_module: command_module, opts: opts] do
      validated_opts =
        Keyword.validate!(opts, [
          :identifier,
          prefix: nil,
          # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
          aggregate: Module.concat(command_module, Aggregate),
          lifespan: Commanded.Boilerplate.Command.DefaultLifespan,
          timeout: 5_000
        ])

      {aggregate, by, prefix, lifespan, timeout} =
        {
          Keyword.fetch!(validated_opts, :aggregate),
          Keyword.fetch!(validated_opts, :identifier),
          Keyword.get(validated_opts, :prefix),
          Keyword.fetch!(validated_opts, :lifespan),
          Keyword.fetch!(validated_opts, :timeout)
        }

      aggregate_identifier = [
        {:by, by},
        prefix && {:prefix, prefix}
      ]

      identify(aggregate, aggregate_identifier)

      dispatch(command_module,
        to: command_module,
        aggregate: aggregate,
        lifespan: lifespan,
        timeout: timeout
      )
    end
  end

  defmacro route_command(command_module) do
    quote do
      router(unquote(command_module))
    end
  end
end
