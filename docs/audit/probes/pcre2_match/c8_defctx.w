use std.builtins.print
use std.builtins.print_i32
use std.re.defs
fn main:
    print("heap=")
    print_i32(unsafe { _pcre2_default_match_context_8.heap_limit } as i32)
    print(" match=")
    print_i32(unsafe { _pcre2_default_match_context_8.match_limit } as i32)
    print(" depth=")
    print_i32(unsafe { _pcre2_default_match_context_8.depth_limit } as i32)
    print("\n")
