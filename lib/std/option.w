// std.option — Option type surface imported by the prelude.
//
// Keep this module minimal for selfhost compatibility. The compiler owns
// the lowering/runtime behavior for option methods and constructors; this
// module provides the user-facing type name so it resolves by import.

/// A value that may or may not be present.
/// `Some(value)` contains a value, `None` represents absence.
///
/// Use `.unwrap()` to extract the value (panics if None),
/// `.unwrap_or(default)` for a safe fallback,
/// `.is_some()` / `.is_none()` to check,
/// `.map(fn)` to transform the inner value.
pub enum Option[T] { Some(T) | None }
