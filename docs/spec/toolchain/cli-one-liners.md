# 18.5b CLI One-Liners

The `with` CLI supports small programs directly on the command line:

```
with -e 'print("hello")'
cat log.txt | with -n 'if line =~ /error (\d+)/: print($1)'
cat names.txt | with -p 'line = line.upper()'
```

One-liners are not interpreted and do not use a separate execution
model. The CLI constructs a synthetic With entry source file, compiles
it through the normal build/run pipeline, runs the resulting binary,
and returns that binary's exit code. The generated source uses
top-level executable statements; the CLI does not generate an explicit
`fn main` wrapper.

A module file holds declarations. A file whose top level also holds
executable statements is an entry source: those statements are its `main`,
run in order, and it may not also declare `fn main`. An imported module may
not hold executable statements. Every command that takes an entry file
(`run`, `build`, `check`, `test`) applies the same rule (D74).

Exactly one one-liner mode may be used in a single invocation:

| Mode | Meaning |
|------|---------|
| `-e CODE` | Compile and run `CODE` as top-level executable statements |
| `-n CODE` | Loop over stdin lines and run `CODE` for each line |
| `-p CODE` | Like `-n`, then print the current `line` after `CODE` |

Multiple flags of the same mode are allowed and concatenate as separate
generated lines:

```
with -e 'var total = 0' -e 'total = total + 1' -e 'print(total)'
```

One-liner code cannot be combined with a source file argument.
