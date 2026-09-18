use std.string

fn main:
    // T10: string_to_int honesty — invalid input returns what?
    print(f"i123={string_to_int("123")} ineg={string_to_int("-42")} iplus={string_to_int("+7")}")
    print(f"iinv={string_to_int("abc")} iempty={string_to_int("")} ipart={string_to_int("12x34")} itrail={string_to_int("  12")}")
    print(f"parse={parse("99")} parseinv={parse("zz")}")
    // T10: lines edges
    let l0 = lines("")
    print(f"lines_empty={l0.len()}")
    let l1 = lines("a\nb\nc")
    print(f"lines3={l1.len()} l0={l1.get(0)} l2={l1.get(2)}")
    let l2 = lines("a\n")
    print(f"lines_trail={l2.len()}")
    let l3 = lines("single")
    print(f"lines1={l3.len()} v={l3.get(0)}")
    // T10: split edges
    let e = "".split(",")
    print(f"split_empty={e.len()}")
    let nd = "abc".split(",")
    print(f"split_nodelim={nd.len()} v={nd.get(0)}")
    let ed = "a,b,".split(",")
    print(f"split_traildelim={ed.len()} last=[{ed.get(ed.len() - 1)}]")
    // T10: cmp/eq/find/contains/prefix/suffix
    print(f"eq={string_eq("a", "a")} cmp={string_cmp("a", "b")} cmp2={string_cmp("b", "a")} cmp3={string_cmp("a", "a")}")
    print(f"find={"hello".find("ll")} findmiss={"hello".find("zz")} contains={"hello".contains("ell")} sw={"hi".starts_with("h")} ew={"hi".ends_with("i")}")
    // T10: is_digit doc says (-9); check 0-9 + is_alpha/space/xdigit/print
    print(f"digit0={is_digit(48)} digit9={is_digit(57)} digita={is_digit(97)} alpha={is_alpha(65)} space={is_space(32)} upper={is_upper(65)} lower={is_lower(122)} xdig={is_xdigit(70)} pr={is_print(32)}")
    // T10: to_cstring loud on interior NUL?
    match "hi".to_cstring():
        Ok(c) => print(f"cok={c.len()}")
        Err(x) => print("cstr-unexpected-err")
    match "a\x00b".to_cstring():
        Ok(c2) => print("cstr-SILENT-TRUNC")
        Err(x2) => print("cstr-loud-InteriorNul")
    // T10: push_char truncation above 255?
    var sb = StringBuilder.new()
    sb.push_char(300)
    print(f"pushchar300_len={sb.len()} b0={sb.to_str().byte_at(0)}")
    // T10: view helpers + CStr
    print(f"vlen={view_len("abc")} ve={view_is_empty("")} veq={view_eq("x", "x")}")
    print(f"slen={string_len("abcd")} isempty={"".is_empty()}")
