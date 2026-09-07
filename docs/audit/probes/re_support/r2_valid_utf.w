use std.libc
use std.re.defs
use std.re.pcre2_context
use std.re.pcre2_valid_utf

// r2: _pcre2_valid_utf_8 vectors. Oracle: python3 strict-decode validity
// + PCRE2 UTF8_ERRn code meaning (ERR1..5 = n bytes missing at end).
unsafe fn check(name: *const i8, bytes: *const u8, len: c_ulong):
    var off: c_ulong = 9999
    let rc = _pcre2_valid_utf_8(bytes, len, &raw mut off)
    printf(c"%s rc=%d off=%lu\n".ptr, name, rc, off)

unsafe fn main:
    let hello = with_alloc(6)
    unsafe { hello[0] = 104 }
    unsafe { hello[1] = 101 }
    unsafe { hello[2] = 108 }
    unsafe { hello[3] = 108 }
    unsafe { hello[4] = 111 }
    check(c"ascii".ptr, hello, 5)
    let e2 = with_alloc(4)   // U+00E9
    unsafe { e2[0] = 195 }
    unsafe { e2[1] = 169 }
    check(c"e-acute".ptr, e2, 2)
    let euro = with_alloc(4) // U+20AC
    unsafe { euro[0] = 226 }
    unsafe { euro[1] = 130 }
    unsafe { euro[2] = 172 }
    check(c"euro".ptr, euro, 3)
    let grin = with_alloc(5) // U+1F600
    unsafe { grin[0] = 240 }
    unsafe { grin[1] = 159 }
    unsafe { grin[2] = 152 }
    unsafe { grin[3] = 128 }
    check(c"grin".ptr, grin, 4)
    let lone = with_alloc(4)
    unsafe { lone[0] = 97 }
    unsafe { lone[1] = 128 }
    unsafe { lone[2] = 98 }
    check(c"lone-trail".ptr, lone, 3)
    let trunc3 = with_alloc(3)
    unsafe { trunc3[0] = 226 }
    check(c"trunc-e2".ptr, trunc3, 1)
    unsafe { trunc3[1] = 130 }
    check(c"trunc-e282".ptr, trunc3, 2)
    let trunc4 = with_alloc(3)
    unsafe { trunc4[0] = 240 }
    unsafe { trunc4[1] = 159 }
    check(c"trunc-f09f".ptr, trunc4, 2)
    let over2 = with_alloc(3)
    unsafe { over2[0] = 192 }
    unsafe { over2[1] = 175 }
    check(c"overlong2".ptr, over2, 2)
    let over3 = with_alloc(4)
    unsafe { over3[0] = 224 }
    unsafe { over3[1] = 128 }
    unsafe { over3[2] = 175 }
    check(c"overlong3".ptr, over3, 3)
    let over4 = with_alloc(5)
    unsafe { over4[0] = 240 }
    unsafe { over4[1] = 128 }
    unsafe { over4[2] = 128 }
    unsafe { over4[3] = 175 }
    check(c"overlong4".ptr, over4, 4)
    let badc = with_alloc(3)
    unsafe { badc[0] = 195 }
    unsafe { badc[1] = 40 }
    check(c"bad-cont".ptr, badc, 2)
    let surr = with_alloc(4)
    unsafe { surr[0] = 237 }
    unsafe { surr[1] = 160 }
    unsafe { surr[2] = 128 }
    check(c"surrogate".ptr, surr, 3)
    let big = with_alloc(5)
    unsafe { big[0] = 244 }
    unsafe { big[1] = 144 }
    unsafe { big[2] = 128 }
    unsafe { big[3] = 128 }
    check(c"beyond-10ffff".ptr, big, 4)
    let fe = with_alloc(2)
    unsafe { fe[0] = 254 }
    check(c"fe".ptr, fe, 1)
    let five = with_alloc(6)
    unsafe { five[0] = 248 }
    unsafe { five[1] = 136 }
    unsafe { five[2] = 128 }
    unsafe { five[3] = 128 }
    unsafe { five[4] = 128 }
    check(c"five-byte".ptr, five, 5)
    let six = with_alloc(7)
    unsafe { six[0] = 252 }
    unsafe { six[1] = 132 }
    unsafe { six[2] = 128 }
    unsafe { six[3] = 128 }
    unsafe { six[4] = 128 }
    unsafe { six[5] = 128 }
    check(c"six-byte".ptr, six, 6)
    let _done = 0
