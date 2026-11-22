//! expect-stdout: str
//! expect-stdout: other
//! expect-stdout: other
//! expect-stdout: ok

// A `comptime if` on `T.name()` inside a generic body is evaluated by the
// comptime evaluator during the specialization recheck that precedes MIR
// lowering. That evaluation writes back a Sema whose eager type caches were
// emptied; the lowering must refresh them or the frozen twins phase-bug
// ("is_copy_frozen miss — type not preregistered: i32").

fn kind[T: Debug](v: &T) -> str:
    comptime if T.name() == "str":
        "str"
    else:
        "other"

fn main:
    print(kind("lit"))
    print(kind(1))
    print(kind(true))
    print("ok")
