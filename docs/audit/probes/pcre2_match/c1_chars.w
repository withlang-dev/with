use std.regex.Regex
use std.builtins.print
fn main:
    // empty pattern vs empty subject (must match empty)
    match Regex.compile(""):
        Ok(re) => print(if re.is_match(""): "empty-empty TRUE" else: "empty-empty FALSE")
        Err(e) => print("compile-err empty")
    // a* must match empty at 0 even vs non-a
    match Regex.compile("a*"):
        Ok(re) => print(if re.is_match("bbb"): "star TRUE" else: "star FALSE")
        Err(e) => print("compile-err star")
    // literal at nonzero offset
    match Regex.compile("a"):
        Ok(re) => {
            print(if re.is_match("a"): "lit TRUE" else: "lit FALSE")
            match re.find_at("xa", 1):
                Some(m) => print("find_at1 ok")
                None => print("find_at1 NONE")
            match re.find_at("xa", 0):
                Some(m) => print("find_at0 ok")
                None => print("find_at0 NONE")
        }
        Err(e) => print("compile-err a")
    // anchored empty-possible
    match Regex.compile("^"):
        Ok(re) => print(if re.is_match("abc"): "caret TRUE" else: "caret FALSE")
        Err(e) => print("compile-err caret")
