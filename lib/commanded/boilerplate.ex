defmodule Commanded.Boilerplate do
  @type result(error) :: :ok | {:error, error}
  @type result(ok, error) :: {:ok, ok} | {:error, error}
end
