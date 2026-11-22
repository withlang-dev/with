//! args: --validate-all --no-prelude
//! expect-check-stdout: validate-all: ok
// #2555: a standard-library module names what it uses, so it compiles
// whatever the prelude holds. Eleven modules besides std.sync read the
// prelude's Result, Option, List or traits and failed in a `--no-prelude`
// program ("unknown type: Result", "unknown trait").
use std.alloc
use std.channel
use std.context
use std.fs
use std.generators
use std.http
use std.io
use std.json
use std.result
use std.string
use std.tls

fn main -> i32:
    0
