{ name = "obr"
, dependencies =
  [ "aff"
  , "aff-promise"
  , "aff-retry"
  , "argonaut-codecs"
  , "argonaut-core"
  , "arrays"
  , "avar"
  , "bifunctors"
  , "console"
  , "control"
  , "datetime"
  , "debug"
  , "effect"
  , "either"
  , "exceptions"
  , "foldable-traversable"
  , "heckin"
  , "integers"
  , "lists"
  , "maybe"
  , "newtype"
  , "nullable"
  , "ordered-collections"
  , "parsing"
  , "partial"
  , "prelude"
  , "profunctor-lenses"
  , "random"
  , "react"
  , "react-basic"
  , "react-basic-dom"
  , "react-basic-hooks"
  , "record"
  , "refs"
  , "routing-duplex"
  , "strings"
  , "tuples"
  , "unsafe-coerce"
  , "web-dom"
  , "web-html"
  , "web-router"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}