// std.option — Option type surface imported by the prelude.
//
// Keep this module minimal for selfhost compatibility. The compiler owns
// the lowering/runtime behavior for option methods and constructors; this
// module provides the user-facing type name so it resolves by import.

enum Option[T] { Some(T) | None }
