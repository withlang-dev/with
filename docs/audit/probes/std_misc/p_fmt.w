use std.fmt

fn expect(label: str, ok: bool):
    if ok:
        print(f"PASS: {label}\n")
    else:
        print(f"FAIL: {label}\n")

fn main():
    expect("fmt_int", fmt_int(42) == "42")
    expect("fmt_int neg", fmt_int(-7) == "-7")
    expect("fmt_int zero", fmt_int(0) == "0")
    expect("fmt_int64", fmt_int64(1234567890123 as i64) == "1234567890123")
    expect("fmt_bool true", fmt_bool(true) == "true")
    expect("fmt_bool false", fmt_bool(false) == "false")
    let f = fmt_float(1.5)
    print(f"fmt_float(1.5) = {f}\n")
    expect("fmt_float nonempty", f.len > 0)
