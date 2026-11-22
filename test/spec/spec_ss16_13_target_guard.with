//! expect-stdout: ok

// §16.13 architecture guards. @[target("arch")] excludes a declaration from
// compilation on any other active target, so the same name can be defined per
// architecture (the "declaration alternative" pattern). A guarded expected()
// mirror makes the assertion hold on whichever architecture is the active host:
// arch_value() must resolve to the definition selected for the active target.

@[target("aarch64")]
fn arch_value() -> i32:
    42

@[target("x86_64")]
fn arch_value() -> i32:
    7

@[target("aarch64")]
fn expected() -> i32:
    42

@[target("x86_64")]
fn expected() -> i32:
    7

fn main:
    if arch_value() == expected():
        print("ok")
    else:
        print("bad")
