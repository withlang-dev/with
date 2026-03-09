// std.traits — trait declarations for the With standard library.
//
// These traits are also registered as builtin trait names in the compiler
// (sema_is_builtin_trait_name), which allows impl blocks to reference them
// even without explicit import. The source definitions here make them
// available through the prelude for documentation and tooling.

pub trait Eq =
    fn eq(self, other: Self) -> bool

pub trait Ord =
    fn cmp(self, other: Self) -> i32

pub trait Hash =
    fn hash_value(self) -> i64

pub trait Debug =
    fn debug_str(self) -> str

pub trait Display =
    fn to_str(self) -> str

pub trait Default =
    fn default() -> Self

pub trait Drop =
    fn drop(self) -> void

pub trait Scoped =
    fn enter(self) -> Self
    fn exit(self) -> void

pub trait ScopedMut =
    fn enter(self) -> Self
    fn exit(self) -> void

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
