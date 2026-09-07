use std.collections
use std.iter

fn str_len_as_i32(s: str) -> i32:
    s.len

fn main():
    let a: [i32; 3] = [1, 2, 3]
    print(f"a.len = {a.len}\n")
    var sv: Vec[str] = Vec.new()
    sv.push("a")
    sv.push("abc")
    print(f"sv.len = {sv.len}\n")
    print(f"direct len a = {"a".len}\n")
    print(f"direct len abc = {"abc".len}\n")
    let lens = map(sv, str_len_as_i32)
    print(f"lens.len = {lens.len}\n")
    print(f"lens sum = {sum(lens)}\n")
