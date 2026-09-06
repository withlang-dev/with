use std.string

fn main:
    print(f"eq={string_eq("a", "a")} cmp={string_cmp("a", "b")} cmp2={string_cmp("b", "a")} cmp3={string_cmp("a", "a")}")
    print(f"find={"hello".find("ll")} findmiss={"hello".find("zz")} contains={"hello".contains("ell")} sw={"hi".starts_with("h")} ew={"hi".ends_with("i")}")
    print(f"digit0={is_digit(48)} digit9={is_digit(57)} digita={is_digit(97)} alpha={is_alpha(65)} space={is_space(32)} upper={is_upper(65)} lower={is_lower(122)} xdig={is_xdigit(70)} pr={is_print(32)}")
    print(f"vlen={view_len("abc")} ve={view_is_empty("")} veq={view_eq("x", "x")}")
    print(f"slen={string_len("abcd")} isempty={"".is_empty()}")
    var sb = StringBuilder.new()
    sb.push_char(300)
    print(f"pushchar300_len={sb.len()} b0={sb.to_str().byte_at(0)}")
