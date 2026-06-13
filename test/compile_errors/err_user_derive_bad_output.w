//! expect-error: return type mismatch

comptime fn derive_badOutput[T: type] -> str:
    "fn generated_bad_output -> i32:\n    \"bad\"\n"

@[derive(BadOutput)]
type BadGenerated { value: i32 }

fn main:
    let _ = BadGenerated { value: 1 }
