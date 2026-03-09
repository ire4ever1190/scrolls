import std/[unittest, strutils]

import scrolls/envFileParser

test "Parse empty file":
  check parseEnvFile("").len == 0

test "Parse comment":
  check parseEnvFile("# Hello").len == 0

test "Parse values":
  let values = parseEnvFile("""
  FOO=BAR
  BUZZ=FOO
  """.unindent())
  check values["FOO"] == "BAR"
  check values["BUZZ"] == "FOO"

test "Parse values mixed with comments":
  let values = parseEnvFile("""
  FOO=BAR
  # Some comment
  BUZZ=FOO
  """.unindent())
  check values["FOO"] == "BAR"
  check values["BUZZ"] == "FOO"
