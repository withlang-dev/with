//! expect-stdout: ok

use std.process

// A test is a child of the build worker that runs its lane, not a worker
// itself. The worker's own switches must not reach it: with
// WITH_BUILD_ACTION_FORCE inherited, every `with build` a behavior test ran
// re-ran targets that were fresh, and no test could observe a skipped target.
fn main:
    assert(env("WITH_BUILD_ACTION_FORCE").len() == 0)
    assert(env("WITH_BUILD_ACTION_WORKER").len() == 0)
    assert(env("WITH_BUILD_TEST_WORKER").len() == 0)
    print("ok")
