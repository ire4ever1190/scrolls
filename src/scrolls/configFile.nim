## .. importdoc:: jsonProvider.nim
## This is a utility module for loading a config file that belongs to your app.
## I recommend to use this with the [JsonProvider]
runnableExamples:
  import scrolls

  import std/[json, options]

  let reader = initConfigurationReader(
    # If config file doesnt exist, defaults are written
    newJsonProvider(getConfigFile("myapp", %*{"foo": "bar"}))
  )

  # Will return "foo" the first time. User can update it to be something else
  assert reader.get("foo", string).isSome()

import std/[appdirs, paths, json, sugar, dirs, strformat, syncio, files]

proc getConfigFile*(appName, ext: string, default: proc(): string): Path =
  ## Returns the config file to use. This is in the form `$XDG_CONFIG_HOME/.config/$appName/config.$ext`
  ## If the file doesn't exist, then `default` is used to fill out the default contents
  let dir = getConfigDir() / Path(appName)
  createDir dir
  result = dir / Path(fmt"config.{ext}")

  # If the file doesn't exist, fill out the defaults
  if not fileExists(result):
    writeFile($result, default())

proc getConfigFile*(appName: string, default: JsonNode): Path =
  ## Like [getConfigFile] but uses a JSON object as the default value
  return getConfigFile(appName, "json", () => default.pretty())
