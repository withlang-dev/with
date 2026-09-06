// Probe pcre2test.valid_utf (the only pub helper in the harness driver).
use std.re.pcre2test

fn check(tag: &str, p: *const u8, n: c_ulong, expect_ok: i32):
    var erroff: c_ulong = 9999
    let rc = unsafe { valid_utf(p, n, &raw mut erroff as *mut c_ulong) }
    print(f"{tag} rc={rc} expect={expect_ok} erroff={erroff as i32}")

fn main():
    var ascii: [5]u8 = [104, 101, 108, 108, 111]
    check("ascii", &raw const ascii[0] as *const u8, 5 as c_ulong, 0)
    var multi: [6]u8 = [104, 195, 169, 108, 108, 111]
    check("multibyte", &raw const multi[0] as *const u8, 6 as c_ulong, 0)
    var trunc: [3]u8 = [97, 98, 195]
    check("truncated", &raw const trunc[0] as *const u8, 3 as c_ulong, 1)
    var lone: [3]u8 = [97, 128, 98]
    check("lone-cont", &raw const lone[0] as *const u8, 3 as c_ulong, 1)
    var overlong: [4]u8 = [240, 130, 130, 172]
    check("overlong", &raw const overlong[0] as *const u8, 4 as c_ulong, 1)
