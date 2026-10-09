//! only-on: windows
//! expect-stdout: ok

// std.process.args() on Windows came from the C runtime's narrow argv: the
// command line in the ANSI code page, so "café" arrived as "caf\xe9" under
// code page 1252 (not UTF-8) and a character the code page lacks arrived
// as "?". The runtime now takes the UCRT's wide argv, parsed by the same
// UCRT routine as the narrow one (the same quoting and backslash rules),
// and hands args() UTF-8. The program re-launches itself with arguments
// that exercise both the text and the quoting.
use std.process

fn byte_list(s: &str) -> str:
    var out = ""
    for i in 0..s.len():
        out = out ++ f"{s[i]} "
    out

fn main:
    let sent = ["café – 😀", "quote \"inside\"", "trailing\\", "", "tab\there"]
    let argv = args()
    if argv.len() > 1 and argv[1] == "--child":
        var same = argv.len() == sent.len() + 2
        for i in 0..sent.len():
            if same and argv[i + 2] != sent[i]:
                same = false
        if not same:
            for i in 2..argv.len():
                print(f"child got [{byte_list(argv[i])}]")
            exit_code(3)
        return
    var child: List[str] = List.new()
    child.push(argv[0] ++ "")
    child.push("--child")
    for a in sent:
        child.push(a.to_owned())
    assert(run(&child) == 0)
    print("ok")
