use std.collections
use std.iter

fn const42(s: str) -> i32:
    42

fn str_len_as_i32(s: str) -> i32:
    s.len

fn main():
    var sv: Vec[str] = Vec.new()
    sv.push("a")
    sv.push("abc")
    let c = map(sv, const42)
    print(f"const-map: len={c.len} [0]={c[0]} [1]={c[1]}\n")
    var sv2: Vec[str] = Vec.new()
    sv2.push("a")
    sv2.push("abc")
    let l = map(sv2, str_len_as_i32)
    print(f"len-map: len={l.len} [0]={l[0]} [1]={l[1]}\n")
