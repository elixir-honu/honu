ExUnit.start()

children = [
  HonuTest.Repo
]
opts = [strategy: :one_for_one, name: HonuTest.Supervisor]
Supervisor.start_link(children, opts)
