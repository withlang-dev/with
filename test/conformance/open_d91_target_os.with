//! expect-stdout: ok
// D91 (§17.5): comptime match Target.os on the release compiler. #2949
pub const NAME: str = comptime match Target.os:
    .Macos => "mac"
    .Linux => "linux"
    .Windows => "win"
    .Wasi => "wasm"
fn main:
    if NAME.len() > 0: print("ok")
