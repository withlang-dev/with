use std.regex
use std.builtins.print
fn show(label: &str, m: Option[Captures]):
    match m:
        Some(c) => {
            match c.get(0):
                Some(found) => print(label ++ "=" ++ found.text)
                None => print(label ++ "=nogroup")
        }
        None => print(label ++ "=none")

fn main:
    let text = "a1 b2"
    let lit = /([a-z])(\\d)/g
    show("lit1", lit.captures_match_op(text))
    show("lit2", lit.captures_match_op(text))
    show("lit3", lit.captures_match_op(text))
    let c = Regex.compile_flags("([a-z])(\\d)", "g").unwrap()
    show("compiled1", c.captures_match_op(text))
    show("compiled2", c.captures_match_op(text))
    show("compiled3", c.captures_match_op(text))
