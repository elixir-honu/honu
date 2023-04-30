# Honu

[![Hex.pm](https://img.shields.io/hexpm/v/honu)](https://hex.pm/packages/honu) [![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/honu/)

https://en.wikipedia.org/wiki/Green_sea_turtle#Taxonomy

**A WIP file upload and attachment library for Ecto**

## Installation

The package can be installed by adding `honu` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:honu, "~> 0.3.1"}
  ]
end
```

## Usage

After installation it's necessary to create a folder in where the files will reside for the default Storage behaviour.

```bash
mkdir storage
touch storage/.keep
echo '# Honu storage\n/storage/*\n!/storage/.keep' >> .gitignore
```

After, generate the migration file for the blobs table:

```bash
mix ecto.gen.migration create_honu_blobs
```

And change the file to the following:

```elixir
defmodule MyApp.Repo.Migrations.CreateHonuBlobs do
  use Ecto.Migration
  require Honu.Migration

  def change do
    Honu.Migration.create_blobs_table()
  end
end
```

Configure the environments accordingly:

```elixir
# dev.exs
config :honu, Honu.Storage,
  storage: Honu.Storage.Disk,
  repo: MyApp.Repo,
  root_dir: "storage"
```

Optional, Honu also was support to serve the attachments.
To do so, add the following configuration to the necessary environments:

```elixir
config :honu, HonuWeb.Storage,
  storage: HonuWeb.Storage.Disk,
  # You can use mix phx.gen.secret to generate the secret
  secret_key_base: "SECRET HERE",
  repo: MyApp.Repo,
  service_urls_expire_in: 300
```

And finally forward the requests to the Honu app.
In phoenix it's possible to do it with the following:

```elixir
# router.ex
scope "/honu" do
  pipe_through :browser
  forward "/", HonuWeb.Router
end
```

Since HonuWeb.Router is just a plug app, it's also possible to add it to other plug apps besides phoenix.
If it's done so, it's important to add CSRF protection for the delete endpoint.

## Guides

[User avatar example](guides/user_avatar.md)
