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
    StringList
    BoolList
    IntList
    DoubleList

  ConfigValue* = object ## Value stored in config
    sensitive*: bool ## If true, then the value shouldn't be logged
    case kind*: ConfigValueKind
    of String: sval*: string
    of Bool: bval*: bool
    of Int: ival*: BiggestInt
    of Double: dval*: BiggestFloat
    of StringList: items*: seq[string]
    of BoolList: bools*: seq[bool]
    of IntList: ints*: seq[BiggestInt]
    of DoubleList: doubles*: seq[BiggestFloat]

  InvalidConfigValue* = ref object of CatchableError
    ## Raised when a key is found but the [ConfigValueKind] asked for does not match
    ## the value
    value*: ConfigValue
    key*: string

  ConfigurationProvider* = ref object of RootObj
    ## Base provider interface that must be implemented by other providers

method value*(
    provider: ConfigurationProvider, key: string, kind: ConfigValueKind
): Option[ConfigValue] {.base.} =
  ## Must be implemented by a provider. This takes a key and returns a [ConfigValue] if its found.
  ## If a key is found but does not meet the `kind` provider, [InvalidConfigValueType] should be thrown
  raise (ref CatchableError)(msg: "Value method has not been implemented")

using value: ConfigValue

proc `$`*(value): string =
  ## Stringifies the config value. For sensitive items only `"********"` is returned
  runnableExamples:
    assert $ConfigValue(kind: String, sval: "Foo") == "Foo"
    assert $ConfigValue(kind: String, sval: "Foo", sensitive: true) == "********"
  if value.sensitive:
    return "********"
  else:
    case value.kind
    of String:
      value.sval
    of Bool:
      $value.bval
    of Int:
      $value.ival
    of Double:
      $value.dval
    of StringList:
      $value.items
    of BoolList:
      $value.bools
    of IntList:
      $value.ints
    of DoubleList:
      $value.doubles
