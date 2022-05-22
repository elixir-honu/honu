defmodule Honu.SchemaTest do
  use ExUnit.Case

  alias HonuTest.Book
  alias HonuTest.User

  test "has_one_attached/2" do
    assert %User{}.avatar.__cardinality__ == :one
  end

  @tag :skip
  test "has_one_attached/3" do
    # TODO
  end

  test "has_many_attached/2" do
    assert %User{}.documents.__cardinality__ == :many
  end

  test "has_many_attached/3" do
    assert %Book{}.pages.__cardinality__ == :many
  end
end
