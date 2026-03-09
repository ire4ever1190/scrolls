import ./scrolls/[envProvider, configReader]

export envProvider, configReader

## .. importdoc:: scrolls/envProvider
## This library abstracts reading configuration files so that there is a single interface
## for reading but multiple backwards to pull values from. Current supported backends are
## - [EnvProvider] which reads from environment variables
## - [JsonProvider] which reads from a JSON file
