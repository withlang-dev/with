use std.io

fn main -> i32:
    let first5 = read_bytes(5)
    print("first5=[" ++ first5 ++ "]")
    let rest = read_line()
    print("rest=[" ++ rest ++ "]")
    let all = read_all()
    print("all_len=" ++ all.len().to_string())
    print("all=[" ++ all ++ "]")
    let nlines = stdin.lines()
    print("lines_after_eof=" ++ nlines.len().to_string())
    0
