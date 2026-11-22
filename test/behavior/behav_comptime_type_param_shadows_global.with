//! expect-stdout: str
//! expect-stdout: other
//! expect-stdout: g
//! expect-stdout: ok

// Inside a generic body, a bound type parameter named `T` shadows a module
// global named `T`: `T.name()` in `comptime if` names the instance's type,
// not the caller's global. The comptime evaluator once resolved the ident
// through the module's let-decls first and reported the condition as not
// comptime-evaluable.

var T = ""

fn kind[T: Debug](v: &T) -> str:
    comptime if T.name() == "str":
        "str"
    else:
        "other"

fn main:
    T = T ++ "g"
    print(kind("lit"))
    print(kind(1))
    print(T)
    print("ok")
