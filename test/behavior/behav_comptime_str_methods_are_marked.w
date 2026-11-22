//! expect-stdout: AB A|ab a|Ab a|Ab a|3|a bA|2|true|4
// D227: the methods of `str` are functions of the standard library, and a
// program evaluates them at compile time because std.string declares them
// `comptime fn`, the ones the evaluator runs itself included. `upper`,
// `trim_start`, `rfind`, `reverse` and `fields` were refused while `trim`,
// `to_upper` and `find` were accepted.
const UP: str = comptime "Ab a".upper()
const LOW: str = comptime "Ab a".lower()
const TS: str = comptime "  Ab a".trim_start()
const TE: str = comptime "Ab a  ".trim_end()
const RF: isize = comptime "Ab a".rfind("a")
const REV: str = comptime "Ab a".reverse()
const FIELDS: isize = comptime "Ab a".fields().len()
const STARTS: bool = comptime "Ab a".starts_with("Ab")
const LEN: isize = comptime "Ab a".len()

fn main:
    print(f"{UP}|{LOW}|{TS}|{TE}|{RF}|{REV}|{FIELDS}|{STARTS}|{LEN}")
