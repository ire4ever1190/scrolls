# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import std/[unittest, envvars, options, json, tables]

import scrolls

suite "Environment provider":
  const testValues = {"FOO_BAR": "hello world", "BUZZES": "foo,bar,buzz"}

  setup:
    for (key, value) in testValues:
      putEnv(key, value)

  teardown:
    for (key, _) in testValues:
      delEnv(key)

  let reader = initConfigurationReader(newEnvProvider(Path("test.env")))

  test "Can access basic key":
    check reader.get("foo.bar", string) == some("hello world")

  test "Environment file are parsed":
    check reader.get("some.value", string) == some("BAR")

suite "JSON provider":
  let reader =
    initConfigurationReader(newJsonProvider(%*{"foo": {"bar": 1}, "hello": "world"}))

  test "Can access basic key":
    check reader.get("hello", string) == some("world")

  test "Can access nested key":
    check reader.get("foo.bar", int) == some(1)

type StaticProvider = ref object of ConfigurationProvider
  data: Table[string, ConfigValue]

method value*(
    provider: StaticProvider, key: string, kind: ConfigValueKind
): Option[ConfigValue] =
  if key in provider.data:
    return some provider.data[key]

suite "Config Reader":
  let reader = initConfigurationReader(
    StaticProvider(
      data: toTable {
        "string": ConfigValue(kind: String, sval: "Hello"),
        "integer": ConfigValue(kind: Int, ival: 1),
        "boolean": ConfigValue(kind: Bool, bval: true),
        "double": ConfigValue(kind: Double, dval: 3.14),
        "stringList": ConfigValue(kind: StringList, items: @["a", "b", "c"]),
        "boolList": ConfigValue(kind: BoolList, bools: @[true, false, true]),
        "intList": ConfigValue(kind: IntList, ints: @[1, 2, 3]),
        "doubleList": ConfigValue(kind: DoubleList, doubles: @[1.1, 2.2, 3.3]),
      }
    )
  )

  test "String value":
    check reader.get("string", string) == some("Hello")

  test "Integer value":
    check reader.get("integer", int) == some(1)

  test "Boolean value":
    check reader.get("boolean", bool).get()

  test "Double value":
    check reader.get("double", float) == some(3.14)

  test "String list value":
    check reader.get("stringList", seq[string]) == some(@["a", "b", "c"])

  test "Bool list value":
    check reader.get("boolList", seq[bool]) == some(@[true, false, true])

  test "Int list value":
    check reader.get("intList", seq[int]) == some(@[1, 2, 3])

  test "Double list value":
    check reader.get("doubleList", seq[float]) == some(@[1.1, 2.2, 3.3])

  test "Doesn't error on missing key":
    check reader.get("missing", string).isNone()

  test "Can convert into object":
    type
      InnerObj = object
        field: bool

      Obj = object
        name: string
        withDefault = "hello"
        optional: Option[int]
        inner: InnerObj

    let reader = initConfigurationReader(
      StaticProvider(
        data: toTable {
          "name": ConfigValue(kind: String, sval: "Hello"),
          "inner.field": ConfigValue(kind: Bool, bval: true),
          "optional": ConfigValue(kind: Int, ival: 1),
        }
      )
    )

    check reader.get(Obj) ==
      Obj(
        name: "Hello",
        withDefault: "hello",
        optional: some(1),
        inner: InnerObj(field: true),
      )
