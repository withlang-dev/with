//! expect-stdout: true
//! expect-stdout: first-value-long

// env() returns an owned str. It wrapped libc's environment bytes, so a
// saved value was rewritten in place by the next set_env ("/aabb value-long",
// on main too); every copy of a str shares its buffer under D111, which made
// the runner's save-and-restore of WITH_OUT_DIR restore garbage.
use std.process

fn main:
    let target = "/aa" ++ "bb"
    assert(set_env("WTEST_ENV_SURVIVES", "first-value-long") == 0)
    let saved = env("WTEST_ENV_SURVIVES")
    assert(set_env("WTEST_ENV_SURVIVES", target) == 0)
    print(env("WTEST_ENV_SURVIVES") == target)
    print(saved)
