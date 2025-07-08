defmodule BackendFight.Redis do
  @callback command(atom(), [binary()]) :: {:ok, binary()} | {:error, term()}
end
