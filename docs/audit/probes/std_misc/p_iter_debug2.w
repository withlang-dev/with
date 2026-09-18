use std.collections
use std.iter

fn str_len_as_i32(s: str) -> i32:
    print(f"  f got: [{s}] len={s.len}\n")
    s.len

fn main():
    var sv: Vec[str] = Vec.new()
    sv.push("a")
    sv.push("abc")
    print(f"sv[0] = [{sv[0]}] len={sv[0].len}\n")
    print(f"sv[1] = [{sv[1]}] len={sv[1].len}\n")
    let lens = map(sv, str_len_as_i32)
    print(f"lens[0] = {lens[0]}\n")
    print(f"lens[1] = {lens[1]}\n")
