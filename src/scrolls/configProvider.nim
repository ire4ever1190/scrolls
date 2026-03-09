import std/[options, tables, strutils]

## This module contains the base config provider. This interface must be implemented for custom
## providers

type
  ConfigValueKind* = enum
    ## Different kind of values that can be stored in config
    String
    Bool
    Int
    Double
    List
    Table
  ConfigValue* = object
    ## Value stored in config
    sensitive*: bool ## If true, then the value shouldn't be logged
    case kind*: ConfigValueKind
    of String: sval*: string
    of Bool: bval*: bool
    of Int: ival*: BiggestInt
    of Double: dval*: BiggestFloat
    of List: items*: seq[ConfigValue]
    of Table: mapping*: Table[string, ConfigValue]

  Key* = seq[string]
    ## Key to access a config value

  ConfigurationProvider = ref object of RootObj
    ## Base provider interface that must be implemented by other providers

proc parseKey*(key: string): Key =
  ## Parses a key in the form `"some.key.foo"` into `["some", "key", "foo"]`
  for part in key.split("."):
    result &= part

method value*(provider: ConfigurationProvider, key: Key): Option[ConfigValue] {.base.} =
  ## Must be implemented by a provider. This takes a key and returns a [ConfigValue] if its found
  raise (ref CatchableError)(msg: "Value method has not been implemented")

proc value*(provider: ConfigurationProvider, key: string): Option[ConfigValue] =
  provider.value(key.parseKey())
