use std.libc
use std.re.defs
use std.re.pcre2_context
use std.re.pcre2_maketables

// T15c: pcre2_maketables_8(null) output must equal _pcre2_default_tables_8.
// Prints mismatch count + first mismatch index (expect 0 / -1).
unsafe fn main:
    let t = pcre2_maketables_8(null)
    if (t as i64) == 0:
        printf(c"maketables_null=1\n".ptr)
    else:
        var bad: i32 = 0
        var first: i32 = -1
        var i: i32 = 0
        while i < 1088:
            if (unsafe t[i]) != _pcre2_default_tables_8[i]:
                bad = bad + 1
                if first < 0:
                    first = i
            i = i + 1
        printf(c"mismatch=%d first=%d\n".ptr, bad, first)
        pcre2_maketables_free_8(null, t)
