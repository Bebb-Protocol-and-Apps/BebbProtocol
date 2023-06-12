let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.6.21-20220215/package-set.dhall sha256:b46f30e811fe5085741be01e126629c2a55d4c3d6ebf49408fb3b4a98e37589b
let aviate-labs = https://github.com/aviate-labs/package-set/releases/download/v0.1.3/package-set.dhall sha256:ca68dad1e4a68319d44c587f505176963615d533b8ac98bdb534f37d1d6a5b47

let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }

let
  -- This is where you can add your own packages to the package-set
  additions =
    [
      { name = "io"
      , repo = "https://github.com/aviate-labs/io.mo"
      , version = "v0.3.0"
      , dependencies = [ "base" ]
      },
      { name = "rand"
      , repo = "https://github.com/aviate-labs/rand.mo"
      , version = "v0.2.1"
      , dependencies = [ "base" ]
      },
      { name = "uuid"
      , version = "88871a6e1801c61ba54d42966f08be0604bb2a2d"
      , repo = "https://github.com/aviate-labs/uuid.mo"
      , dependencies = [ "base", "encoding", "io" ]
      },
    ] : List Package

let
  {- This is where you can override existing packages in the package-set

     For example, if you wanted to use version `v2.0.0` of the foo library:
     let overrides = [
         { name = "foo"
         , version = "v2.0.0"
         , repo = "https://github.com/bar/foo"
         , dependencies = [] : List Text
         }
     ]
  -}
  overrides =
    [] : List Package

in  upstream # aviate-labs # additions # overrides
