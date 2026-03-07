// std.result — Result type surface imported by the prelude.
//
// Keep this module minimal for selfhost compatibility. The compiler owns
// the lowering/runtime behavior for result methods and constructors; this
// module provides the user-facing type names so they resolve by import.

type Result[T, E] = | Ok(T) | Err(E)

type ContextError[E] = {
    msg: str
    source: E
}
