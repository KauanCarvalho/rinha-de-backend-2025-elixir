defmodule BackendFight.DistributedLock do
  @default_ttl 5

  @spec acquire(any(), keyword()) :: :error | {:ok, binary()}
  @doc """
  Executes the given function if lock is acquired. Automatically releases after.
  """
  def with_lock(key, fun, opts \\ []) when is_function(fun, 0) do
    case acquire(key, opts) do
      {:ok, value} ->
        try do
          fun.()
        after
          release(key, value)
        end

      :error ->
        :lock_not_acquired
    end
  end

  @doc """
  Acquires a Redis lock using SET NX EX.
  Returns {:ok, lock_value} if acquired, or :error if already held.
  """
  def acquire(key, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @default_ttl)

    value =
      [:positive]
      |> :erlang.unique_integer()
      |> Integer.to_string()

    case redis().command(:redix, ["SET", key, value, "NX", "EX", "#{ttl}"]) do
      {:ok, "OK"} -> {:ok, value}
      _ -> :error
    end
  end

  @doc """
  Releases the Redis lock, only if it holds the expected value.
  Uses a Lua script to ensure atomic check-and-delete.
  """
  def release(key, value) do
    lua = """
    if redis.call("GET", KEYS[1]) == ARGV[1] then
      return redis.call("DEL", KEYS[1])
    else
      return 0
    end
    """

    case redis().command(:redix, ["EVAL", lua, "1", key, value]) do
      {:ok, 1} -> :ok
      _ -> :error
    end
  end

  defp redis, do: Application.get_env(:backend_fight, :redis_module, Redix)
end
