//! expect-stdout: ok

// §16.13 architecture guards. @[target("arch")] excludes a declaration from
// compilation on any other active target, so the same name can be defined per
// architecture (the "declaration alternative" pattern). This test assumes an
// aarch64 host/CI; on an x86_64 host the surviving definition returns 7.

@[target("aarch64")]
fn arch_value() -> i32:
    42

@[target("x86_64")]
fn arch_value() -> i32:
    7

fn main:
    if arch_value() == 42:
        print("ok")
    else:
        print("bad")
