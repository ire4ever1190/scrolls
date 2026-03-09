## Wrapper around multiple providers. Gives an easy interface for accessing values
## and converting them into proper types.
## If a key doesn't exist then `None(T)` is returned. If it does exist but is in the wrong format then [InvalidFormat] is raised

import ./configProvider

import std/[options, sugar]

type
  ConfigurationReader* = object
    ## Wrapper around multiple providers.
    ## This allows a hierarchy of trying to find a key in the first provider and then
    ## stepping through the rest until a value is found
    providers: seq[ConfigurationProvider]

proc initConfigurationReader*(providers: varargs[ConfigurationProvider]): ConfigurationReader =
  ConfigurationReader(providers: @providers)

using reader: ConfigurationReader
using key: string

proc value(reader; key; kind: ConfigValueKind): Option[ConfigValue] =
  ## Wrapper around all the providers. Calls them in order and returns the
  ## first found value
  for provider in reader.providers:
    let res = provider.value(key, kind)
    if res.isSome:
      return res

proc get*(reader; key; typ: typedesc[string]): Option[string] =
  ## Attempts to read a string value from providers
  reader.value(key, String).map(val => val.sval)

proc get*[T: SomeInteger](reader; key; typ: typedesc[T]): Option[T] =
  ## Attempts to read an integer value from providers. Will be
  ## casted into the type asked for
  reader.value(key, Int).map(val => T(val.ival))
