use std.regex
use std.builtins.print
use std.builtins.ToString
fn main:
    let text = "a1 b2"
    let lit = /([a-z])(\\d)/g
    print("ismatch=" ++ if lit.is_match(text): "yes" else: "no")
    print("findall=" ++ lit.find_all(text).len().to_string())
    if text =~ /([a-z])(\\d)/g:
        print("op=" ++ $0)
    else:
        print("op=none")
