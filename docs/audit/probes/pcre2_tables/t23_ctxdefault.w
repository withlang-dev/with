use std.libc
use std.re.defs
use std.re.pcre2_context

// T23c (#1009 trail): the default match-context image must NOT be zeroed.
// Expect match=10000000 depth=10000000 heap=20000000 offmax=1, and a
// freshly created context must copy those values (not zeros).
unsafe fn main:
    printf(c"def_match=%d depth=%d heap=%d offmax=%d\n".ptr, ((_pcre2_default_match_context_8.match_limit) as i32), ((_pcre2_default_match_context_8.depth_limit) as i32), ((_pcre2_default_match_context_8.heap_limit) as i32), (if (_pcre2_default_match_context_8.offset_limit) == ((0 as c_ulong) -% (1 as c_ulong)): 1 else: 0))
    let mc = pcre2_match_context_create_8(null)
    if (mc as i64) == 0:
        printf(c"create_null=1\n".ptr)
    else:
        printf(c"new_match=%d depth=%d heap=%d offmax=%d\n".ptr, ((unsafe mc.match_limit) as i32), ((unsafe mc.depth_limit) as i32), ((unsafe mc.heap_limit) as i32), (if (unsafe mc.offset_limit) == ((0 as c_ulong) -% (1 as c_ulong)): 1 else: 0))
        pcre2_match_context_free_8(mc)
