//! only-on: windows
//! expect-stdout: ok

// Environment names and values cross the same UTF-8/UTF-16 boundary as
// paths. SetEnvironmentVariableW got each UTF-8 byte as one UTF-16 unit, and
// GetEnvironmentVariableW's answer came back with `?` for every non-ASCII
// unit. The buffers were fixed as well: a value longer than 8191 units was
// cut short on the way in, and one longer than 16383 read back as "", both
// without an error.
use std.process
use std.string

fn main:
    let value = "café – 😀"
    assert(set_env("WITH_BEHAV_UNICODE_VALUE", value) == 0)
    assert(env("WITH_BEHAV_UNICODE_VALUE") == value)
    assert(set_env("WITH_BEHAV_ÜNICODE_NAME", "named") == 0)
    assert(env("WITH_BEHAV_ÜNICODE_NAME") == "named")
    // 20000 UTF-16 units (40000 UTF-8 bytes): past both old buffers and
    // under the 32767-unit limit Windows sets on one variable.
    var long = StringBuilder.new()
    for _ in 0..4000:
        long.push_str("é–😀x")
    let long_value = long.to_str()
    assert(set_env("WITH_BEHAV_UNICODE_LONG", long_value) == 0)
    assert(env("WITH_BEHAV_UNICODE_LONG") == long_value)
    print("ok")
