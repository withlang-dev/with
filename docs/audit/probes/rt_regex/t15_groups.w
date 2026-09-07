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
    // numbered groups + capture text
    match Regex.compile("(ab)+(12)?"):
        Ok(re) => {
            check("groups-n", re.num_captures() == 2)
            match re.captures("abab12"):
                Some(cap) => {
                    check("g0", cap.text(0) == "abab12")
                    check("g1", cap.text(1) == "ab")
                    check("g2", cap.text(2) == "12")
                }
                None => {
                    check("g0", false)
                }
            // optional group unmatched -> empty text
            match re.captures("abab"):
                Some(cap) => {
                    check("g2-unset", cap.text(2) == "")
                }
                None => {
                    check("g2-unset", false)
                }
        }
        Err(e) => {
            print_str("COMPILE-FAIL groups ")
            print_str(e.message.clone())
            print_str("\n")
        }
    // named groups
    match Regex.compile("(?<year>[0-9]{4})-(?<month>[0-9]{2})"):
        Ok(re) => {
            check("names-n", re.num_captures() == 2)
            match re.captures("2026-09"):
                Some(cap) => {
                    check("by-year", cap.name_text("year") == "2026")
                    check("by-month", cap.name_text("month") == "09")
                    check("by-idx", cap.text(1) == "2026")
                }
                None => {
                    check("by-year", false)
                }
            check("cap-idx-month", re.capture_index("month") == Some(2))
            check("cap-idx-missing", re.capture_index("day").is_none())
        }
        Err(e) => {
            print_str("COMPILE-FAIL names ")
            print_str(e.message.clone())
            print_str("\n")
        }
    // alternation
    match Regex.compile("cat|dog"):
        Ok(re) => {
            check("alt-cat", re.is_match("cat"))
            check("alt-dog", re.is_match("dog"))
            check("alt-neg", re.is_match("cow") == false)
        }
        Err(e) => {
            print_str("COMPILE-FAIL alt ")
            print_str(e.message.clone())
            print_str("\n")
        }
    // flags: i (caseless), m (multiline ^), s (dotall .)
    match Regex.compile_flags("abc", "i"):
        Ok(re) => {
            check("flag-i", re.is_match("ABC"))
        }
        Err(e) => {
            print_str("COMPILE-FAIL flag-i ")
            print_str(e.message.clone())
            print_str("\n")
        }
    match Regex.compile_flags("^b", "m"):
        Ok(re) => {
            check("flag-m", re.is_match("a\nb"))
            check("flag-m-neg", re.is_match("ab") == false)
        }
        Err(e) => {
            print_str("COMPILE-FAIL flag-m ")
            print_str(e.message.clone())
            print_str("\n")
        }
    match Regex.compile_flags("a.b", "s"):
        Ok(re) => {
            check("flag-s", re.is_match("a\nb"))
        }
        Err(e) => {
            print_str("COMPILE-FAIL flag-s ")
            print_str(e.message.clone())
            print_str("\n")
        }
    match Regex.compile("a.b"):
        Ok(nodot) => {
            check("no-dotall", nodot.is_match("a\nb") == false)
        }
        Err(e) => {
            print_str("COMPILE-FAIL no-s ")
            print_str(e.message.clone())
            print_str("\n")
        }
