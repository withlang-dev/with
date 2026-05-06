// Minimal repro for compiler diagnostic-path segfault
// Stage fresh migration into lib/std/re/ first:
//   cp out/pcre2_generated/*.w lib/std/re/
// Then: with build out/diagnose/reproducers/compiler_segfault.w -o /tmp/bug
// Expected: shadowing errors printed and exit 1.
// Actual: silent SIGSEGV (exit 139).
use std.re.defs
use std.re.pcre2_ucd
use std.re.pcre2_context
fn main: print("ok\n")
