defmodule Honu.Schema do
  defmacro __using__(_) do
    quote do
      import Honu.Schema,
        only: [
          has_one_attached: 2,
          has_one_attached: 3,
          has_many_attached: 2,
          has_many_attached: 3
        ]
    end
  end

  defmacro has_one_attached(name, queryable, opts \\ []) do
    opts = attached_opts(name, opts)

    quote do
      Ecto.Schema.has_one(unquote(name), unquote(queryable), unquote(opts))
    end
  end

  defmacro has_many_attached(name, queryable, opts \\ []) do
    opts = attached_opts(name, opts)

    quote do
      Ecto.Schema.has_many(unquote(name), unquote(queryable), unquote(opts))
    end
  end

  defp attached_opts(name, opts) do
    {where_opts, opts} = Keyword.pop(opts, :where, [])

    opts
    |> Keyword.put(:foreign_key, :record_id)
    |> Keyword.put(:on_replace, :delete_if_exists)
    |> Keyword.put(:where, Keyword.put(where_opts, :name, to_string(name)))
  end
end
