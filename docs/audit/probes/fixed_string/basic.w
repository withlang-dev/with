// FixedString[N] behavioral probe. Method surface is compiler-intrinsic
// (SemaCheck.w:20738-20771, CodegenDispatch.w:7298); lib/std/fixed_string.w
// itself only declares the type + Copy impl.

use std.fixed_string.FixedString
use std.builtins.int_to_string


fn main:
    var s: FixedString[16] = FixedString[16].new()
    if s.is_empty() and s.len_i32() == 0 and s.capacity() == 16:
        print("PASS new/empty/len/capacity")
    else:
        print("FAIL new state")
    s.push_byte(65 as u8)
    s.push_str("BC")
    if s.len_i32() == 3:
        print("PASS len after push_byte+push_str")
    else:
        print("FAIL len got: " ++ int_to_string(s.len_i32()))
    if s.equals("ABC"):
        print("PASS equals ABC")
    else:
        print("FAIL equals ABC")
    if s.as_view() == "ABC":
        print("PASS as_view")
    else:
        print("FAIL as_view got: " ++ s.as_view())
    if s[0] == 65 as u8 and s[2] == 67 as u8:
        print("PASS index")
    else:
        print("FAIL index")
    s.clear()
    if s.is_empty() and s.len_i32() == 0:
        print("PASS clear")
    else:
        print("FAIL clear")
    // Observation pin: overflow past capacity (behavior recorded verbatim,
    // no oracle claimed).
    var t: FixedString[4] = FixedString[4].new()
    t.push_str("ABCDE")
    print("OBS overflow len=" ++ int_to_string(t.len_i32()) ++ " view=" ++ t.as_view())
