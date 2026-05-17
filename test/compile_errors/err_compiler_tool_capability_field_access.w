//! expect-error: tool capability fields are private; use capability methods instead

use std.compiler

fn leak_token(source: SourceEmitter) -> str:
    source.token

fn main:
    print("unreachable")
