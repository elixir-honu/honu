import Config

config :honu,
  ecto_repos: [HonuTest.Repo]

if System.get_env("CI") do
  config :honu, HonuTest.Repo,
    username: System.get_env("POSTGRES_USERNAME", "postgres"),
    password: System.get_env("POSTGRES_PASSWORD", "postgres"),
    hostname: "localhost",
    database: "honu_test#{System.get_env("MIX_TEST_PARTITION")}",
    pool: Ecto.Adapters.SQL.Sandbox,
    pool_size: 10
else
  config :honu, HonuTest.Repo,
    hostname: "localhost",
    database: "honu_test#{System.get_env("MIX_TEST_PARTITION")}",
    pool: Ecto.Adapters.SQL.Sandbox,
    pool_size: 10
end

config :honu, Honu.Storage,
  # TODO: Add in memory storage behaviour or clean directory after test
  storage: Honu.Storage.Disk,
  repo: HonuTest.Repo,
  root_dir: "storage"

config :logger, level: :warn
