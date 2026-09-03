//! expect-stdout: ok

// The regex-literal entry points codegen calls (CodegenDispatch
// .gen_regex_literal_value): `Regex.__literal_code(slot, &str, options)`
// compiles a literal once into its slot, `Regex.__capture_count(code)` reads
// the count the literal's value carries. Called here as the facade declares
// them, so a signature change fails this test before it fails every regex
// literal — and the literal itself agrees with them.

use std.regex

var slot: *const i8 = null

fn main:
    let first = unsafe { Regex.__literal_code(&raw mut slot, "(a)(b)?", 0) }
    let again = unsafe { Regex.__literal_code(&raw mut slot, "(a)(b)?", 0) }
    let literal = /(a)(b)?/
    if first as i64 != 0 and again as i64 == first as i64 and Regex.__capture_count(first) == 2 and literal.num_captures() == 2:
        print("ok")
