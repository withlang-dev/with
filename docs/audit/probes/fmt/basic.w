use std.fmt


// Oracles: python3 str() for ints/bools (exact decimal, independent of
// rt/rt_core.w i64_to_buf/u64 paths); python3 repr for the two float pins.
fn main:
    let i64min = (-9223372036854775807) - 1
    if fmt_int(0) == "0":
        print("PASS fmt_int(0)")
    else:
        print("FAIL fmt_int(0) got: " ++ fmt_int(0))
    if fmt_int(-42) == "-42":
        print("PASS fmt_int(-42)")
    else:
        print("FAIL fmt_int(-42) got: " ++ fmt_int(-42))
    if fmt_int(2147483647) == "2147483647":
        print("PASS fmt_int(i32max)")
    else:
        print("FAIL fmt_int(i32max) got: " ++ fmt_int(2147483647))
    if fmt_int(-2147483648) == "-2147483648":
        print("PASS fmt_int(i32min)")
    else:
        print("FAIL fmt_int(i32min) got: " ++ fmt_int(-2147483648))
    if fmt_int64(9223372036854775807) == "9223372036854775807":
        print("PASS fmt_int64(i64max)")
    else:
        print("FAIL fmt_int64(i64max) got: " ++ fmt_int64(9223372036854775807))
    if fmt_int64(i64min) == "-9223372036854775808":
        print("PASS fmt_int64(i64min)")
    else:
        print("FAIL fmt_int64(i64min) got: " ++ fmt_int64(i64min))
    if fmt_bool(true) == "true":
        print("PASS fmt_bool(true)")
    else:
        print("FAIL fmt_bool(true) got: " ++ fmt_bool(true))
    if fmt_bool(false) == "false":
        print("PASS fmt_bool(false)")
    else:
        print("FAIL fmt_bool(false) got: " ++ fmt_bool(false))
    if fmt_float(1.5) == "1.5":
        print("PASS fmt_float(1.5)")
    else:
        print("FAIL fmt_float(1.5) got: " ++ fmt_float(1.5))
    if fmt_float(-0.5) == "-0.5":
        print("PASS fmt_float(-0.5)")
    else:
        print("FAIL fmt_float(-0.5) got: " ++ fmt_float(-0.5))
    // Observation pins (no exact oracle claimed; recorded verbatim):
    print("OBS fmt_float(0.0) = " ++ fmt_float(0.0))
    print("OBS fmt_float(3.14159) = " ++ fmt_float(3.14159))
