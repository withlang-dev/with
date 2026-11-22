// std.option — Option type surface imported by the prelude.
//
// Keep this module minimal for selfhost compatibility. The compiler owns
// the lowering/runtime behavior for option methods and constructors; this
// module provides the user-facing type name so it resolves by import.
// It imports the trait it implements: a module with no prelude (a migrated
// corpus holding `Option[extern "C" fn]` fields, D102) reaches `Option`
// through `use std.option` alone.

use std.traits

/// A value that may or may not be present.
/// `Some(value)` contains a value, `None` represents absence.
///
/// Use `.unwrap()` to extract the value (panics if None),
/// `.unwrap_or(default)` for a safe fallback,
/// `.is_some()` / `.is_none()` to check,
/// `.map(fn)` to transform the inner value.
///
/// TODO(D22 — implementation in progress): the normative Option surface also
/// includes `.copied()` for `Option[&T] where T: Copy` and `.cloned()` for
/// `Option[&T] where T: Clone`. All eliminators preserve view origins until an
/// explicit ownership boundary; do not implement these as conditional unwrap
/// return types.
// `None` is declared first (D97): derived Ord orders variants by declaration,
// so nothing sorts before any value.
pub enum Option[T] { None | Some(T) }

// An Option carries no ownership beyond its payload. Copy payloads therefore
// make the whole wrapper Copy; non-Copy payloads remain single-owner values.
impl[T: Copy] Copy for Option[T]

/// An Option is Clone when its payload is: `Some` holds a clone of it.
impl[T: Clone] Clone for Option[T]:
    fn clone() -> Self:
        match self:
            Some(value) => Some(value.clone())
            None => None
