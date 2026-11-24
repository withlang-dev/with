# First-hour scenarios

These are not `with uat` scenarios. A `*.uat` file checks that a program we
wrote still runs. A first-hour scenario checks what a new user meets: an
agent is given a task, the public documentation and `with` on its PATH, and
nothing else. The postal-mcp transcript was this test run by accident, and
it found a dozen defects in an hour that no battery lane could see (#3133).

## The scenarios

One file per task in this directory. Each states the task as a user would
bring it and the library they would reach for. It does not say how.

| File | Task | Library |
|---|---|---|
| `post-json.md` | POST JSON with headers and read the status | libcurl |
| `store-and-query.md` | store rows and query them back | sqlite3 |
| `parse-config.md` | parse a JSON configuration file | std.json, yyjson |
| `compress-file.md` | compress a file and read it back | zstd |
| `draw-window.md` | open a window and draw in it | raylib, SDL |
| `verify-signature.md` | verify a signature over a message | libsodium |
| `mcp-over-stdio.md` | serve MCP over standard input and output | std.json |

## Running one

1. Start an agent in an empty directory with `with` on its PATH. Give it the
   scenario file and the public documentation (`docs/spec`, `with --help`,
   `with <command> --help`). It does not get this repository's source,
   tests, `examples/` or `uat/`.
2. The agent builds the program with `with init`, `with get` and `with run`,
   and stops when the program does what the task says or an hour has gone.
3. The agent keeps a log. A line goes in the log each time it had to:
   - guess (the documentation did not say);
   - write `unsafe`;
   - copy from the compiler's repository or its tests;
   - rename around a keyword;
   - work around a compiler error, or could not tell from the error what to
     change;
   - give up on a library on its platform.
4. Each line of the log becomes an issue labelled `first-hour`, with the
   scenario, the platform, what was written, what happened, and what the
   user expected. One issue per defect, not per run.

Run every scenario before a release and after any change to `with get`, the
facade engine or the diagnostics a new user sees first. A scenario whose
library `with get` cannot provide on a platform (uat/README.md lists them)
is run on the platforms where it can.

## The release gate

An open `first-hour` issue blocks a release: a first-hour failure costs more
trust than a missing feature. The release runbook checks it
(`docs/spec/toolchain/with-release-runbook.md`, "Verification"):

    gh issue list --state open --label first-hour

must print nothing.
