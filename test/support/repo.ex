defmodule HonuTest.Repo do
  use Ecto.Repo,
    otp_app: :honu,
    adapter: Ecto.Adapters.Postgres
end
