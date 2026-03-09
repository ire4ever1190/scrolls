## This implements a `.env` file parser.
## Supports comments at the start of a line with `#`
## ```
## # This is a comment
## KEY=VALUE
## ```

import pkg/nort
import pkg/nort/helpers

import std/[strutils, tables]

export tables

let grammar = block:
  let nlo = nl | fin()
  let comment = e('#') * dot().untilIncl(nlo)
  let key = +e(IdentChars)
  let value = dot().untilIncl(nlo)
  any((comment: comment, variable: key $ key * e('=') * value $ value))

proc parseEnvFile*(data: string): Table[string, string] =
  for line in grammar.match(data):
    case branch(line)
    of variable:
      result[line.variable.key] = line.variable.value
    else:
      discard
