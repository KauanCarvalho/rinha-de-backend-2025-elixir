defmodule BackendFight.Redis do
  @callback command(atom(), [binary()]) :: {:ok, binary()} | {:error, term()}
  @callback command!(atom(), [binary()]) :: binary() | no_return()
end
