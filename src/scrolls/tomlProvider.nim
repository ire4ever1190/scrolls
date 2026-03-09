import ./configProvider

import std/[envvars, options, strutils, sugar, sequtils, paths, streams]

import pkg/parsetoml

export configProvider

## .. importdoc:: jsonProvider.nim
## This provider reads from TOML files. Works like the [JsonProvider] with keyed access.
## Currently dates/times are not supported

type TomlProvider* = ref object of ConfigurationProvider
  ## Provider that reads config stored in TOML
  data: TomlValueRef

proc newTomlProvider*(data: TomlValueRef): TomlProvider =
  ## Returns a new TOML provider that has set data.
  ## Useful for testing or hard coded values
  TomlProvider(data: data)

proc newTomlProvider*(stream: Stream): TomlProvider =
  ## Returns a new TOML provider that reads TOML from
  ## a stream
  TomlProvider(data: stream.parseStream())

proc newTomlProvider*(file: Path): TomlProvider =
  ## Returns a new TOML provider that has read the data
  ## from a file
  TomlProvider(data: parseFile($file))

proc parseValue(value: TomlValueRef, kind: ConfigValueKind): ConfigValue =
  ## Parses a string into a `ConfigValue` using our rules
  template parseValues(field: untyped): untyped =
    collect(
      for val in value.arrayVal:
        val.field
    )

  case kind
  of String:
    ConfigValue(kind: String, sval: value.stringVal)
  of Bool:
    ConfigValue(kind: Bool, bval: value.boolVal)
  of Int:
    ConfigValue(kind: Int, ival: value.intVal)
  of Double:
    ConfigValue(kind: Double, dval: value.floatVal)
  of StringList:
    ConfigValue(kind: StringList, items: parseValues(stringVal))
  of BoolList:
    ConfigValue(kind: BoolList, bools: parseValues(boolVal))
  of IntList:
    ConfigValue(kind: IntList, ints: parseValues(intVal))
  of DoubleList:
    ConfigValue(kind: DoubleList, doubles: parseValues(floatVal))


method value*(
    provider: TomlProvider, key: string, kind: ConfigValueKind
): Option[ConfigValue] =
  ## Implementation of the value provider.
  ## Keys are style sensitive and perform object access
  provider.data{key.split(".")}.option().map(val => val.parseValue(kind))
