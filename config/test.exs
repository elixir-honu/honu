import Config

config :honu,
  ecto_repos: [HonuTest.Repo]

config :honu, HonuTest.Repo,
  hostname: "localhost",
  database: "honu_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :honu, Honu.Storage,
  # TODO: Add in memory storage behaviour or clean directory after test
  storage: Honu.Storage.Disk,
  repo: HonuTest.Repo,
  root_dir: "storage"

config :logger, level: :warn
