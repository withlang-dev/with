use std.regex.Regex
use std.builtins.print
fn main:
    match Regex.compile("a"):
        Ok(re) => print(re.replace("a", "b"))
        Err(e) => print("compile-err")
