//! env: WITH_CODEGEN_UNITS=8
//! expect-stdout: 42
//! expect-stdout: ok

// #681 codegen units: a unit that emitted a foreign `@[c_export]` it does
// not own demotes it to a declaration, and a declaration carries no
// definition subprogram. Its body was deleted with the subprogram left on,
// and LLVM refused the unit ("function declaration may only have a unique
// !dbg attachment"); the in-unit runtime's __isPlatformVersionAtLeast hit
// it under D30's lane.
@[c_export("with_test_answer")]
fn answer() -> i32: 42

fn main:
    print(f"{answer()}")
    var parts: List[str] = List.new()
    for word in ["o", "k"]: parts.push(word)
    print(parts.join(""))
