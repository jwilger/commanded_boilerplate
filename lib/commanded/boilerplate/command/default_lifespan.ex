defmodule Commanded.Boilerplate.Command.DefaultLifespan do
  @moduledoc """
  Stops the aggregate after a command, event or error.

  It is always better to first prioritize reliability over performance. This
  lifespan module prevents Aggregate processes from hanging around indefinitely
  (the questionable default behaviour of Commanded) and stops them immediately
  after command execution. Snapshots can help avoid load times on aggregates
  with many events, and it is possible to define an alternative lifespan for
  certain commands/aggregates if perf-testing shows aggregate load time to be a
  bottleneck on frequently updated data.
  """

  @behaviour Commanded.Aggregates.AggregateLifespan

  @doc """
  Stops the aggregate after a command.
      iex> OnePiece.Commanded.Aggregate.StatelessLifespan.after_command(%MyCommandOne{})
      :stop
  """
  @impl Commanded.Aggregates.AggregateLifespan
  def after_command(_command), do: :stop

  @doc """
  Stops the aggregate after an event.
      iex> OnePiece.Commanded.Aggregate.StatelessLifespan.after_event(%DepositAccountOpened{})
      :stop
  """
  @impl Commanded.Aggregates.AggregateLifespan
  def after_event(_event), do: :stop

  @doc """
  Stops the aggregate after an error.
      iex> OnePiece.Commanded.Aggregate.StatelessLifespan.after_error({:error, :something_happened})
      :stop
  """
  @impl Commanded.Aggregates.AggregateLifespan
  def after_error(_error), do: :stop
end
