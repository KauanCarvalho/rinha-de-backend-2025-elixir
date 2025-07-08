defmodule BackendFight.DistributedLockTest do
  use ExUnit.Case, async: true

  import Mox
  alias BackendFight.DistributedLock

  setup :verify_on_exit!

  describe "with_lock/3" do
    test "executes the function when lock is acquired" do
      key = "lock:test"

      expect(BackendFight.RedisMock, :command, fn :redix, ["SET", ^key, _, "NX", "EX", _] ->
        {:ok, "OK"}
      end)

      expect(BackendFight.RedisMock, :command, fn :redix, ["EVAL", _lua, "1", ^key, _] ->
        {:ok, 1}
      end)

      assert DistributedLock.with_lock(key, fn -> :done end) == :done
    end

    test "returns :lock_not_acquired when lock is already held" do
      key = "lock:test"

      expect(BackendFight.RedisMock, :command, fn :redix, ["SET", ^key, _, "NX", "EX", _] ->
        :error
      end)

      assert DistributedLock.with_lock(key, fn -> flunk("should not run") end) ==
               :lock_not_acquired
    end

    test "still releases lock even if function raises" do
      key = "lock:test"

      expect(BackendFight.RedisMock, :command, fn :redix, ["SET", ^key, _, "NX", "EX", _] ->
        {:ok, "OK"}
      end)

      expect(BackendFight.RedisMock, :command, fn :redix, ["EVAL", _lua, "1", ^key, _] ->
        {:ok, 1}
      end)

      assert_raise RuntimeError, "fail", fn ->
        DistributedLock.with_lock(key, fn -> raise "fail" end)
      end
    end
  end

  describe "acquire/2" do
    test "returns {:ok, value} on success" do
      expect(BackendFight.RedisMock, :command, fn :redix,
                                                  ["SET", "lock:acquire", _, "NX", "EX", _] ->
        {:ok, "OK"}
      end)

      assert {:ok, _} = DistributedLock.acquire("lock:acquire")
    end

    test "returns :error when lock not acquired" do
      expect(BackendFight.RedisMock, :command, fn :redix,
                                                  ["SET", "lock:acquire", _, "NX", "EX", _] ->
        :error
      end)

      assert :error = DistributedLock.acquire("lock:acquire")
    end
  end

  describe "release/2" do
    test "returns :ok when key is deleted" do
      expect(BackendFight.RedisMock, :command, fn :redix,
                                                  ["EVAL", _lua, "1", "lock:release", "abc"] ->
        {:ok, 1}
      end)

      assert DistributedLock.release("lock:release", "abc") == :ok
    end

    test "returns :error when key was not deleted" do
      expect(BackendFight.RedisMock, :command, fn :redix,
                                                  ["EVAL", _lua, "1", "lock:release", "abc"] ->
        {:ok, 0}
      end)

      assert DistributedLock.release("lock:release", "abc") == :error
    end

    test "returns :error on Redis failure" do
      expect(BackendFight.RedisMock, :command, fn :redix,
                                                  ["EVAL", _lua, "1", "lock:release", "abc"] ->
        {:error, :conn_lost}
      end)

      assert DistributedLock.release("lock:release", "abc") == :error
    end
  end
end
