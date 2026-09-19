//! env: WITH_WASM_FIXTURE=present
//! expect-stdout: argc=1
//! expect-stdout: arg0 set: true
//! expect-stdout: env=present
//! expect-stdout: os=Wasi arch=wasm32

use std.process
use std.sysinfo

fn main:
    let argv = args()
    print(f"argc={argv.len()}")
    print(f"arg0 set: {argv.get(0).len() > 0}")
    print(f"env={env("WITH_WASM_FIXTURE")}")
    print(f"os={os()} arch={arch()}")
