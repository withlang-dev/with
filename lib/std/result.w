// std.result — Result type surface imported by the prelude.
//
// Keep this module minimal for selfhost compatibility. The compiler owns
// the lowering/runtime behavior for result methods and constructors; this
// module provides the user-facing type names so they resolve by import.

/// A value that is either a success (`Ok`) or a failure (`Err`).
///
/// Use the `?` operator to propagate errors: `let val = try_something()?`
/// Use `.unwrap()` to extract Ok (panics on Err),
/// `.is_ok()` / `.is_err()` to check,
/// `.map(fn)` / `.map_err(fn)` to transform.
enum Result[T, E] { Ok(T) | Err(E) }

/// Error type returned by compiler-generated `@[derive(Builder)]`
/// `.build()` methods when a required field has not been supplied.
error BuilderError =
    | MissingField(str)

/// An error with a message and an underlying source error.
type ContextError[E]  {
    message: str
    source: E
}
