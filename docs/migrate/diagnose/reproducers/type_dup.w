// Minimal repro for type duplication across modules.
// Setup as above.
// Expected: build succeeds.
// Actual: "shadowing is not allowed for 'BOOL'" etc.
use std.re.defs
use std.re.pcre2_context
use std.re.pcre2_match
fn main: print("ok\n")
