//! expect-stdout: literal 3, compiled 3, again 3, clone 3
// #980: `=~` with a compiled `g` regex walks the matches as a `/g` literal
// does. The compiled value had no place to keep its position, so
// `while text =~ re` returned the first match forever.
use std.regex

fn main:
    let text = "a1 b2 c3"
    var lit = 0
    while text =~ /[0-9]/g:
        lit += 1
        if lit > 10: break
    let re = Regex.compile_flags("[0-9]", "g").unwrap()
    var first = 0
    while text =~ re:
        first += 1
        if first > 10: break
    var second = 0
    while text =~ re:
        second += 1
        if second > 10: break
    let twin = re.clone()
    var cloned = 0
    while text =~ twin:
        cloned += 1
        if cloned > 10: break
    print(f"literal {lit}, compiled {first}, again {second}, clone {cloned}")
