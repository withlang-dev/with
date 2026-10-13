//! expect-stdout: ok

use pre_d_build_runner

// D124 (#2329): a nonnegative constant that wraps in a cast (`300 as
// u8` is 44) is almost always a typo, so it warns; a value that fits
// and the negative-constant idiom (`-1 as u32`) stay silent.
fn main:
    let dir = p7_prepare_case("d124_wrapping_cast", "wrapcast")
    p7_write(dir, "main.w", "fn main:\n    let a = 300 as u8\n    let b = 255 as u8\n    let c = -1 as u32\n    let d = 70000 as i16\n    print(f\"{a} {b} {c} {d}\")\n")
    let checked = p7_run(dir, "d124-wrapping-cast", "check\0main.w\0")
    p7_assert_success(checked, "with check")
    assert(checked.stderr.contains("warning: constant 300 wraps in cast to u8"))
    assert(checked.stderr.contains("warning: constant 70000 wraps in cast to i16"))
    assert(checked.stderr.split("[wrapping-constant-cast]").len() == 3)
    print("ok")
