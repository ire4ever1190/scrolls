# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import std/[unittest, envvars, options, json, tables]

import scrolls

suite "Environment provider":
  const testValues = {
    "FOO_BAR": "hello world",
    "BUZZES": "foo,bar,buzz"
  }

  setup:

    for (key, value) in testValues:
      putEnv(key, value)

  teardown:
    for (key, _) in testValues:
      delEnv(key)

  let reader = initConfigurationReader(newEnvProvider())

  test "Can access basic key":
    check reader.get("foo.bar", string) == some("hello world")

suite "JSON provider":
  let reader = initConfigurationReader(newJsonProvider(%* {
    "foo": {
      "bar": 1
    },
    "hello": "world"
  }))

  test "Can access basic key":
    check reader.get("hello", string) == some("world")

  test "Can access nested key":
    check reader.get("foo.bar", int) == some(1)

type
  StaticProvider = ref object of ConfigurationProvider
    data: Table[string, ConfigValue]
method value*(provider: StaticProvider, key: string, kind: ConfigValueKind): Option[ConfigValue] =
  if key in provider.data:
    return some provider.data[key]

suite "Config Reader":
  let reader = initConfigurationReader(StaticProvider(data: toTable {
    "string": ConfigValue(kind: String, sval: "Hello"),
    "integer": ConfigValue(kind: Int, ival: 1),
    "boolean": ConfigValue(kind: Bool, bval: true)
  }))

  test "String value":
    check reader.get("string", string) == some("Hello")

  test "Integer value":
    check reader.get("integer", int) == some(1)

  test "Boolean value":
    check reader.get("boolean", bool).get()

  test "Doesn't error on missing key":
    check reader.get("missing", string).isNone()
