// Minimal repro for enum-member duplication across modules.
// Setup as above.
// Expected: build succeeds with a single let per name.
// Actual: 500+ "shadowing is not allowed for 'ucp_C'" etc.
use std.re.defs
use std.re.pcre2_ucd
use std.re.pcre2_tables
fn main: print("ok\n")
