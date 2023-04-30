locals_without_parens = [
  # Schema
  has_one_attached: 2,
  has_one_attached: 3,
  has_many_attached: 2,
  has_many_attached: 3
]

[
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ],
  import_deps: [:ecto],
  inputs: ["*.{ex,exs}", "{lib,test}/**/*.{ex,exs}"]
]
