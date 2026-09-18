use std.string

fn main:
    var sb = StringBuilder.new()
    sb.push_char(300)
    print(f"pushchar300_len={sb.len()} b0={sb.to_str().byte_at(0)}")
