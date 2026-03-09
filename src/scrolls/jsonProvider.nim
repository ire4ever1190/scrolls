import ./configProvider

import std/[envvars, options, strutils, sugar, sequtils, paths, json, streams]

export configProvider

## This provider reads from JSON data. Keys are treated as object access
## e.g. The key "hello.world" for `{"hello": {"world": "foo"}}` returns "foo"

type
  JsonProvider* = ref object of ConfigurationProvider
    ## Provider that reads config stored in JSON
    data: JsonNode

proc newJsonProvider*(data: JsonNode): JsonProvider =
  ## Returns a new JSON provider that has set data.
  ## Useful for testing or hard coded values
  JsonProvider(data: data)

proc newJsonProvider*(stream: Stream): JsonProvider =
  ## Returns a new JSON provider that reads JSON from
  ## a stream
  JsonProvider(data: stream.parseJson())

proc newJsonProvider*(file: Path): JsonProvider =
  ## Returns a new JSON provider that has read the data
  ## from a file
  JsonProvider(data: parseFile($file))

proc parseValue(value: JsonNode, kind: ConfigValueKind): ConfigValue =
  ## Parses a string into a `ConfigValue` using our rules
  template parseValues(field: untyped): untyped =
    collect(for val in value: val.field)

  case kind
  of String: ConfigValue(kind: String, sval: value.str)
  of Bool: ConfigValue(kind: Bool, bval: value.bval)
  of Int: ConfigValue(kind: Int, ival: value.num)
  of Double: ConfigValue(kind: Double, dval: value.fnum)
  of StringList:
    ConfigValue(kind: StringList, items: parseValues(str))
  of BoolList:
    ConfigValue(kind: BoolList, bools: parseValues(bval))
  of IntList:
    ConfigValue(kind: IntList, ints: parseValues(num))
  of DoubleList:
    ConfigValue(kind: DoubleList, doubles: parseValues(fnum))

proc accessPath(node: JsonNode, key: string): Option[JsonNode] =
  ## Performs deep retrival of a node via key
  var curr = node

  # Access the value
  for part in key.split("."):
    if part notin curr:
      return none(JsonNode)
    curr = curr[part]

  return some(curr)

method value*(provider: JsonProvider, key: string, kind: ConfigValueKind): Option[ConfigValue] =
  ## Implementation of the value provider.
  ## Keys are style sensitive and perform object access

  return provider.data.accessPath(key).map(val => val.parseValue(kind))
