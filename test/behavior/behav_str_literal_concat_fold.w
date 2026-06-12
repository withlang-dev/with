//! expect-stdout: ab
//! expect-stdout: one	two
//! expect-stdout: three
//! expect-stdout: a-mid-b
//! expect-stdout: xyz

// All-literal ++ chains fold to a single literal at lowering. Escapes sit
// at fold boundaries on purpose; mixed literal/runtime chains still take
// the runtime concat path.
fn xyz_chain() -> str:
    "x" ++ "y" ++ "z"

fn main:
    print("a" ++ "b")
    print("one\t" ++ "two\n" ++ "three")
    let mid = "mid"
    print("a-" ++ mid ++ "-b")
    print(xyz_chain())
