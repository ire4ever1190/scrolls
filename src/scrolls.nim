import ./scrolls/[envProvider, jsonProvider, configReader, configFile]

export envProvider, jsonProvider, configReader, configFile

## .. importdoc:: scrolls/envProvider.nim, scrolls/jsonProvider.nim
## This library abstracts reading configuration files so that there is a single interface
## for reading but multiple backwards to pull values from. Current supported backends are
## - [EnvProvider] which reads from environment variables
## - [JsonProvider] which reads from a JSON file

runnableExamples:
  import std/[envvars, json, options]

  # Usually you'd set environment variables before you start the program...
  putenv("ENV_EXAMPLE", "true")

  # You'll need to make a reader with all the providers you want.
  # These providers are read in order
  let reader = initConfigurationReader(
    newEnvProvider(), # We want environment variables to have highest priority
    newJsonProvider(
      %*{ # We use hard coded values, but could use a JSON config file
        "json": {"example": "hello"}
      }
    ),
  )

  assert reader.get("env.example", bool).get() # It can parse types
  assert reader.get("json.example", string).get() == "hello" # Handles fall through
  assert reader.get("doesnt.exist", string).isNone()
