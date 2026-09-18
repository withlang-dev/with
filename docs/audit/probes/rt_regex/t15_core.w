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
    // character class + span
    match Regex.compile("[a-z]+"):
        Ok(re) => {
            check("class-match", re.is_match("abc"))
            check("class-nomatch", re.is_match("ABC123") == false)
            match re.find("xxabcxx"):
                Some(m) => {
                    check("class-start", m.start == 2)
                    check("class-end", m.end == 5)
                }
                None => {
                    check("class-start", false)
                    check("class-end", false)
                }
        }
        Err(e) => {
            print_str("COMPILE-FAIL class ")
            print_str(e.message.clone())
            print_str("\n")
        }
    // negated class + digit shorthand
    match Regex.compile("[^0-9]+"):
        Ok(re) => {
            check("negclass", re.is_match("abc"))
            match re.find("ab12cd"):
                Some(m) => {
                    check("negclass-span", m.start == 0 and m.end == 2)
                }
                None => {
                    check("negclass-span", false)
                }
        }
        Err(e) => {
            print_str("COMPILE-FAIL negclass ")
            print_str(e.message.clone())
            print_str("\n")
        }
    match Regex.compile("\\d+"):
        Ok(re) => {
            match re.find("ab12cd"):
                Some(m) => {
                    check("digit-span", m.start == 2 and m.end == 4)
                }
                None => {
                    check("digit-span", false)
                }
        }
        Err(e) => {
            print_str("COMPILE-FAIL digit ")
            print_str(e.message.clone())
            print_str("\n")
        }
    // quantifiers: greedy {2,3} takes 3 of 4; ? optional; * empty match
    match Regex.compile("a{2,3}"):
        Ok(re) => {
            match re.find("aaaa"):
                Some(m) => {
                    check("counted", m.start == 0 and m.end == 3)
                }
                None => {
                    check("counted", false)
                }
            check("counted-short", re.is_match("a") == false)
        }
        Err(e) => {
            print_str("COMPILE-FAIL counted ")
            print_str(e.message.clone())
            print_str("\n")
        }
    match Regex.compile("colou?r"):
        Ok(re) => {
            check("opt-color", re.is_match("color"))
            check("opt-colour", re.is_match("colour"))
            check("opt-neg", re.is_match("colouur") == false)
        }
        Err(e) => {
            print_str("COMPILE-FAIL opt ")
            print_str(e.message.clone())
            print_str("\n")
        }
    match Regex.compile("a*"):
        Ok(re) => {
            match re.find("bbb"):
                Some(m) => {
                    check("star-empty", m.start == 0 and m.end == 0)
                }
                None => {
                    check("star-empty", false)
                }
        }
        Err(e) => {
            print_str("COMPILE-FAIL star ")
            print_str(e.message.clone())
            print_str("\n")
        }
    // anchors
    match Regex.compile("^abc$"):
        Ok(re) => {
            check("anchor-full", re.is_match("abc"))
            check("anchor-neg", re.is_match("xabc") == false)
            check("anchor-neg2", re.is_match("abcdef") == false)
        }
        Err(e) => {
            print_str("COMPILE-FAIL anchor ")
            print_str(e.message.clone())
            print_str("\n")
        }
    match Regex.compile("^abc"):
        Ok(re) => {
            check("anchor-prefix", re.is_match("abcdef"))
            check("anchor-prefix-neg", re.is_match("xabc") == false)
        }
        Err(e) => {
            print_str("COMPILE-FAIL anchor2 ")
            print_str(e.message.clone())
            print_str("\n")
        }
