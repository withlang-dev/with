//! expect-error: derive Builder missing required field 'host' before build()

use std.result.BuilderError
@[derive(Builder)]
type Config {
    host: str,
    port: i32 = 8080,
}

fn main:
    let _ = Config.builder().port(443).build()
