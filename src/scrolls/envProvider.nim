import ./[configProvider, envFileParser]

import std/[envvars, options, strutils, sugar, sequtils, tables, paths, files]

export configProvider, paths

## Use this provider for reading from either environment variables or `.env` files (Defaults to one in the current directory)
## Keys are converted into environment variables via the following rules
## - Key components are converted into underscores e.g. `foo.barBuzz` becomes `foo_barBuzz`
## - Camel case is converted into underscores e.g. `foo_barBuzz` becomes `foo_bar_buzz`
## - Everything becomes capitalised e.g. `foo_bar_buzz` becomes `FOO_BAR_BUZZ`
## See [convertKey] for all the rules.
##
## All [ConfigValueKind] types are supported. With some special rules
## - `bool`: `y, yes, true, 1, on` all return `true`. `n, no, false, 0, off` all return false (See [parseBool](https://nim-lang.org/docs/strutils.html#parseBool%2Cstring))
## - `lists`: Values are parsed as comma separated values with whitespaced stripped.
##
## ENV file parsing is laid out in [envFileParser](envFileParser.html). Values in .env files supersed values that are from the environment
runnableExamples:
  import std/[envvars, options]

  let provider = newEnvProvider()

  # An example key
  putEnv("FOO_BAR", "Hello world")

  assert provider.value("foo.bar", String).get().sval == "Hello world"

type EnvProvider* = ref object of ConfigurationProvider
  ## Configuration provider that reads from environment variables
  internalVariables: Table[string, string] ## Env variables we parsed from .env files

proc convertKey*(key: string): string =
  ## Converts a key into an environment variable
  runnableExamples:
    const conversions = {
      "foo.bar": "FOO_BAR",
      # Camel case is supported
      "foo.barBuzz": "FOO_BAR_BUZZ",
      "foo.bar.buzz": "FOO_BAR_BUZZ",
      "foo.userID": "FOO_USER_ID",
    }

    for (input, output) in conversions:
      assert input.convertKey() == output

  result = newStringOfCap(key.len + 5)
    # Preallocate most of it, giving a bit extra for camels
  var isCamelStart = false
  for c in key:
    case c
    of '.':
      result &= '_'
    of 'A' .. 'Z':
      if isCamelStart:
        result &= '_'
        isCamelStart = false
      result &= c
    else:
      isCamelStart = true
      result &= c.toUpperAscii()

proc newEnvProvider*(envFile = Path(".env")): EnvProvider =
  result = EnvProvider()

  # See if we can parse any .env files
  if envFile.fileExists:
    result.internalVariables = readFile($envFile).parseEnvFile()

iterator getValues(value: string): string =
  ## Parses a list of values from environment variables
  for value in value.split(','):
    yield value.strip()

proc parseValue(value: string, kind: ConfigValueKind): ConfigValue =
  ## Parses a string into a `ConfigValue` using our rules
  template parseValues(operation: untyped): untyped =
    collect(
      for val in getValues(value):
        operation(val)
    )

  case kind
  of String:
    ConfigValue(kind: String, sval: value)
  of Bool:
    ConfigValue(kind: Bool, bval: parseBool(value))
  of Int:
    ConfigValue(kind: Int, ival: parseBiggestInt(value))
  of Double:
    ConfigValue(kind: Double, dval: parseFloat(value))
  of StringList:
    ConfigValue(kind: StringList, items: getValues(value).toSeq())
  of BoolList:
    ConfigValue(kind: BoolList, bools: parseValues(parseBool))
  of IntList:
    ConfigValue(kind: IntList, ints: parseValues(parseBiggestInt))
  of DoubleList:
    ConfigValue(kind: DoubleList, doubles: parseValues(parseFloat))

proc tryEnv(key: string): Option[string] =
  ## Tries to return an environment variable
  if not existsEnv(key):
    return none(string)
  else:
    return some(getenv(key))

method value*(
    provider: EnvProvider, key: string, kind: ConfigValueKind
): Option[ConfigValue] =
  let key = convertKey(key)
  # First check if the environment file had it
  if key in provider.internalVariables:
    some provider.internalVariables[key].parseValue(kind)
  else:
    key.tryEnv().map(val => val.parseValue(kind))
