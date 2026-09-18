use std.regex.Regex
use std.builtins.print
fn main:
    match Regex.compile("a"):
        Ok(re) => {
            print(if re.is_match("a"): "match-true" else: "match-FALSE")
            match re.find("xa"):
                Some(m) => print("find ok")
                None => print("find-NONE")
        }
        Err(e) => print("compile-err")
