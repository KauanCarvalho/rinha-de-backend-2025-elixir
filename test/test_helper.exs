ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(BackendFight.Repo, :manual)

# Mocks
Mox.defmock(BackendFight.RedisMock, for: BackendFight.Redis)
