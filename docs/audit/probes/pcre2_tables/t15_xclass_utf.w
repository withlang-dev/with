use std.libc
use std.re.defs
use std.re.pcre2_context
use std.re.pcre2_xclass

// T15d: _pcre2_xclass_8 must honor utf=0 for 8-bit range items.
// data = flags(0), XCLASS_RANGE(2), x=0xE9, y=0xE9, END(0), pad(y2)=0xFF.
// Correct utf=0: c=0xE9 in [0xE9,0xE9] -> 1. Forced-utf=1 mis-decodes -> 0.
// Control: utf=1 with UTF-8 encoded range [U+00E9,U+00E9] -> 1 either way.
unsafe fn main:
    var data: [8]u8 = [0, 2, 233, 233, 0, 255, 0, 0]
    let d = (&raw const data[0] as *const u8)
    let r0 = _pcre2_xclass_8((233 as c_uint), d, (d + (5 as usize)), (0 as c_int))
    printf(c"xclass_nonutf_range=%d\n".ptr, r0)
    var data2: [8]u8 = [0, 2, 195, 169, 195, 169, 0, 255]
    let e = (&raw const data2[0] as *const u8)
    let r1 = _pcre2_xclass_8((233 as c_uint), e, (e + (7 as usize)), (1 as c_int))
    printf(c"xclass_utf_range=%d\n".ptr, r1)
