// std.traits — trait declarations for the With standard library.
//
// These traits are also registered as builtin trait names in the compiler
// (sema_is_builtin_trait_name), which allows impl blocks to reference them
// even without explicit import. The source definitions here make them
// available through the prelude for documentation and tooling.

/// Equality comparison. Implement to enable `==` and `!=` operators.
pub trait Eq =
    fn eq(self, other: Self) -> bool

/// Ordering comparison. Implement to enable `<`, `>`, `<=`, `>=`.
/// Return negative for less-than, 0 for equal, positive for greater-than.
pub trait Ord =
    fn cmp(self, other: Self) -> i32

/// Hashing. Implement to use a type as a HashMap key or HashSet element.
pub trait Hash =
    fn hash_value(self) -> i64

/// Debug formatting. Used by `f"{value:?}"` format specifier.
pub trait Debug =
    fn debug_str(self) -> str

/// Display formatting. Used by `f"{value}"` string interpolation.
pub trait Display =
    fn to_str(self) -> str

/// Default value construction. Call `Type.default()` to get the zero value.
pub trait Default =
    fn default() -> Self

/// Cloning. Creates an independent copy of a value.
pub trait Clone =
    fn clone(self: &Self) -> Self

/// Destructor. Called automatically when a value goes out of scope.
pub trait Drop =
    fn drop(self) -> void

/// Scoped access (immutable). Used with `with` blocks for lock-based access.
pub trait Scoped =
    fn enter(self) -> Self
    fn exit(self) -> void

/// Scoped access (mutable). Used with `with` blocks for mutable lock-based access.
pub trait ScopedMut =
    fn enter(self) -> Self
    fn exit(self) -> void

/// Iterator protocol. Call `.next()` to get `Option[T]` — `Some(val)` or `None`.
pub trait Iter[T] =
    fn next(self) -> Option[T]

/// Conversion to iterator. Enables `for x in collection.iter()`.
pub trait IntoIter[T] =
    fn iter(self) -> VecIter[T]

// IntoIter for Vec — enables `for x in vec.iter()` via trait dispatch
impl[T] IntoIter[T] for Vec[T] =
    fn iter(self: Vec[T]) -> VecIter[T]:
        self.iter()

// Core trait impls for primitive types

impl Eq for i32 =
    fn eq(self: i32, other: i32) -> bool:
        self == other

impl Eq for bool =
    fn eq(self: bool, other: bool) -> bool:
        self == other

impl Default for i32 =
    fn default() -> i32:
        0

impl Default for bool =
    fn default() -> bool:
        false

impl Eq for str =
    fn eq(self: str, other: str) -> bool:
        self == other

impl Eq for i64 =
    fn eq(self: i64, other: i64) -> bool:
        self == other

impl Debug for i32 =
    fn debug_str(self: i32) -> str:
        with_i32_to_str(self)

impl Debug for bool =
    fn debug_str(self: bool) -> str:
        if self:
            "true"
        else:
            "false"

impl Debug for str =
    fn debug_str(self: str) -> str:
        "\"" ++ self ++ "\""

impl Hash for i32 =
    fn hash_value(self: i32) -> i64:
        (1469598103934665603 *% 1099511628211) ^ (self as i64)

impl Hash for i64 =
    fn hash_value(self: i64) -> i64:
        (1469598103934665603 *% 1099511628211) ^ self

impl Hash for bool =
    fn hash_value(self: bool) -> i64:
        if self:
            1
        else:
            0

impl Hash for str =
    fn hash_value(self: str) -> i64:
        var h: i64 = 1469598103934665603
        var i: i64 = 0
        while i < self.len():
            h = (h *% 1099511628211) ^ self[i]
            i = i + 1
        h
