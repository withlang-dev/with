use std.io
use std.regex.Regex

fn check(name: str, cond: bool):
    if cond:
        print_str("PASS ")
    else:
        print_str("FAIL ")
    print_str(name)
    print_str("\n")

fn main:
    // invalid pattern -> Err with nonzero code (runtime lines 108-112)
    match Regex.compile("("):
        Ok(re) => {
            check("invalid-is-err", false)
        }
        Err(e) => {
            check("invalid-is-err", true)
            check("invalid-code", e.code != 0)
            print_str("invalid-msg=")
            print_str(e.message.clone())
            print_str("\n")
        }
    // unknown flag -> Err from wrapper (regex.w, not runtime)
    match Regex.compile_flags("a", "z"):
        Ok(re) => {
            check("badflag-is-err", false)
        }
        Err(e) => {
            check("badflag-is-err", true)
        }
    // no-match -> None (runtime null path, lines 157-160)
    match Regex.compile("xyz"):
        Ok(re) => {
            check("nomatch-none", re.is_match("abc") == false)
            match re.find("abc"):
                Some(m) => {
                    check("nomatch-find", false)
                }
                None => {
                    check("nomatch-find", true)
                }
            // out-of-range start offsets -> None (runtime line 139 guard)
            match re.find_at("abc", 99):
                Some(m) => {
                    check("oob-high", false)
                }
                None => {
                    check("oob-high", true)
                }
            match re.find_at("abc", 3):
                Some(m) => {
                    check("oob-at-end", false)
                }
                None => {
                    check("oob-at-end", true)
                }
        }
        Err(e) => {
            print_str("COMPILE-FAIL nomatch ")
            print_str(e.message.clone())
            print_str("\n")
        }
    // paren nesting over runtime limit 250 (runtime line 88) -> Err
    var deep = ""
    var i: i64 = 0
    while i < 300:
        deep = deep ++ "("
        i = i + 1
    match Regex.compile(deep):
        Ok(re) => {
            check("nest-limit", false)
        }
        Err(e) => {
            check("nest-limit", true)
        }
    // catastrophic-backtracking shape: must terminate with no match.
    // 30 a's + b; if the engine hung, this probe would time out.
    var evil = ""
    i = 0
    while i < 30:
        evil = evil ++ "a"
        i = i + 1
    evil = evil ++ "b"
    match Regex.compile("(a+)+$"):
        Ok(re) => {
            check("backtrack-nomatch", re.is_match(evil) == false)
        }
        Err(e) => {
            print_str("COMPILE-FAIL backtrack ")
            print_str(e.message.clone())
            print_str("\n")
        }
    // empty pattern observation (no assert on engine choice, print only)
    match Regex.compile(""):
        Ok(re) => {
            print_str("empty-compiles len0-match=")
            if re.is_match(""):
                print_str("true\n")
            else:
                print_str("false\n")
        }
        Err(e) => {
            print_str("empty-rejected code=")
            print_int(e.code)
            print_str("\n")
        }
