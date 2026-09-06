use std.string

fn main:
    print(f"digit0={is_digit(48)} digit9={is_digit(57)} digita={is_digit(97)} alpha={is_alpha(65)} space={is_space(32)} upper={is_upper(65)} lower={is_lower(122)} xdig={is_xdigit(70)} pr={is_print(32)}")
    print(f"vlen={view_len("abc")} ve={view_is_empty("")} veq={view_eq("x", "x")}")
    print(f"slen={string_len("abcd")} isempty={"".is_empty()}")
