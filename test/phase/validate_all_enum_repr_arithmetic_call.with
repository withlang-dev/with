//! args: --validate-all
//! expect-check-stdout: validate-all: ok

enum Flags:
    Bit

fn sink(value: i32): let _ = value

fn use_flag(flags: i32):
    sink(flags + Flags.Bit)

fn main: use_flag(1)
