// std.traits — trait declarations for the With standard library.
//
// These traits are also registered as builtin trait names in the compiler
// (sema_is_builtin_trait_name), which allows impl blocks to reference them
// even without explicit import. The source definitions here make them
// available through the prelude for documentation and tooling.

/// Equality comparison. Implement to enable `==` and `!=` operators.
pub trait Eq:    fn eq(self, other:
    Self) -> bool

/// Ordering comparison. Implement to enable `<`, `>`, `<=`, `>=`.
/// Return negative for less-than, 0 for equal, positive for greater-than.
pub trait Ord:    fn cmp(self, other:
    Self) -> i32

/// Addition. Available for explicit generic bounds; `+` dispatches by the
/// fixed method name `add` on concrete operand types.
pub trait Add[Rhs, Output]:
    fn add(self: &Self, rhs: &Rhs) -> Output

/// Subtraction. Available for explicit generic bounds; `-` dispatches by the
/// fixed method name `sub` on concrete operand types.
pub trait Sub[Rhs, Output]:
    fn sub(self: &Self, rhs: &Rhs) -> Output

/// Multiplication. Available for explicit generic bounds; `*` dispatches by the
/// fixed method name `mul` on concrete operand types.
pub trait Mul[Rhs, Output]:
    fn mul(self: &Self, rhs: &Rhs) -> Output

/// Division. Available for explicit generic bounds; `/` dispatches by the
/// fixed method name `div` on concrete operand types.
pub trait Div[Rhs, Output]:
    fn div(self: &Self, rhs: &Rhs) -> Output

/// Matrix multiplication. Available for explicit generic bounds; `@` dispatches
/// by the fixed method name `matmul` on concrete operand types.
pub trait MatMul[Rhs, Output]:
    fn matmul(self: &Self, rhs: &Rhs) -> Output

/// Unary negation. Available for explicit generic bounds; unary `-` dispatches
/// by the fixed method name `neg` on concrete operand types.
pub trait Neg[Output]:
    fn neg(self: &Self) -> Output

/// Control-flow carrier used by the `Try` syntax trait. `Continue` carries the
/// successful `expr?` value; `Break` carries the residual value for propagation.
pub enum ControlFlow[B, C]:
    Continue(C)
    Break(B)

/// `?` propagation protocol for user carriers. Option and Result use compiler
/// fast paths with the same semantics; user carriers provide both directions
/// explicitly so early return can rebuild the enclosing carrier.
pub trait Try[T, E]:
    fn branch(move self: Self) -> ControlFlow[E, T]
    fn from_break(value: E) -> Self

/// Safe dereference protocol for pointer-like user types. Field and method
/// lookup auto-dereferences through this trait the same way it does through
/// built-in references.
pub trait Deref[T]:
    fn deref(self: &Self) -> &T

/// Hashing. Implement to use a type as a HashMap key or HashSet element.
pub trait Hash:
    fn hash_value(self) -> i64

/// Debug formatting. Used by `f"{value:?}"` format specifier.
pub trait Debug:
    fn debug_str(self) -> str

/// Display formatting. Used by `f"{value}"` string interpolation.
pub trait Display:
    fn to_str(self) -> str

/// Default value construction. Call `Type.default()` to get the zero value.
pub trait Default:
    fn default() -> Self

/// Cloning. Creates an independent copy of a value.
pub trait Clone:    fn clone(self:
    &Self) -> Self

/// Destructor. Called automatically when a value goes out of scope.
pub trait Drop:
    fn drop(self) -> Unit

/// Iterator protocol. Call `.next()` to advance the iterator and return
/// `Option[T]` — `Some(val)` or `None`. The receiver is `mut self: Self`
/// (docs/mut.md Rev 8 §11.1) — the iterator's place is mutated in-place
/// without consuming it, so an iterator bound to a local can be reused
/// across calls. During the bridge phase (P1..P11), `mut self: Self` and
/// consuming `self` produce the same MIR; existing impls written either
/// way continue to satisfy this trait.
pub trait Iter[T]:    fn next(mut self:
    Self) -> Option[T]

/// Conversion to iterator. Enables `for x in collection.iter()`.
pub trait IntoIter[T]:
    fn iter(self) -> VecIter[T]

/// Membership test. Implement to enable `x in collection` and
/// `x not in collection`.
pub trait Contains[T]:    fn contains(self: &Self, value:
    &T) -> bool

/// Scoped read access protocol used by guarded `with` blocks.
pub trait Scoped[T]:    fn with_enter(self:
    &Self) -> T
    fn with_exit(self: &Self) -> Unit

/// Scoped mutable access protocol used by guarded `with ... as mut`.
pub trait ScopedMut[T]:    fn with_enter_mut(self:
    &Self) -> T
    fn with_exit_mut(mut self: Self, value: T) -> Unit

// IntoIter for Vec — enables `for x in vec.iter()` via trait dispatch.
// docs/mut.md Rev 8 §15.8 — `@[iter_of_self]` registers a SHARED borrow on
// the receiver place root for the duration of the enclosing call, so a
// sibling closure that mutably captures the same place is rejected.
impl[T] IntoIter[T] for Vec[T]:    fn iter(self:
    Vec[T]) -> VecIter[T]:
        self.iter()

// Core trait impls for primitive types

impl Eq for i32:    fn eq(self: i32, other:
    i32) -> bool:
        self == other

impl Eq for bool:    fn eq(self: bool, other:
    bool) -> bool:
        self == other

impl Eq for u8:    fn eq(self: u8, other:
    u8) -> bool:
        self == other

impl Default for i32:
    fn default() -> i32:
        0

impl Default for i64:
    fn default() -> i64:
        0

impl Default for u8:
    fn default() -> u8:
        0

impl Default for bool:
    fn default() -> bool:
        false

impl Default for str:
    fn default() -> str:
        ""

impl Eq for str:    fn eq(self: str, other:
    str) -> bool:
        self == other

impl Eq for i64:    fn eq(self: i64, other:
    i64) -> bool:
        self == other

impl Ord for i32:
    fn cmp(self: i32, other: i32) -> i32:
        if self < other: return -1
        if self > other: return 1
        0

impl Ord for i64:
    fn cmp(self: i64, other: i64) -> i32:
        if self < other: return -1
        if self > other: return 1
        0

impl Ord for u8:
    fn cmp(self: u8, other: u8) -> i32:
        if self < other: return -1
        if self > other: return 1
        0

impl Ord for bool:
    fn cmp(self: bool, other: bool) -> i32:
        if self == other: return 0
        if not self and other: return -1
        1

impl Debug for i32:    fn debug_str(self:
    i32) -> str:
        with_i32_to_str(self)

impl Debug for i64:    fn debug_str(self:
    i64) -> str:
        with_i64_to_str(self)

impl Debug for u8:    fn debug_str(self:
    u8) -> str:
        with_i32_to_str(self as i32)

impl Debug for bool:    fn debug_str(self:
    bool) -> str:
        if self:
            "true"
        else:
            "false"

impl Debug for str:    fn debug_str(self:
    str) -> str:
        "\"" ++ self ++ "\""

impl Hash for i32:    fn hash_value(self:
    i32) -> i64:
        (1469598103934665603 *% 1099511628211) ^ (self as i64)

impl Hash for u8:    fn hash_value(self:
    u8) -> i64:
        (1469598103934665603 *% 1099511628211) ^ (self as i64)

impl Hash for i64:    fn hash_value(self:
    i64) -> i64:
        (1469598103934665603 *% 1099511628211) ^ self

impl Hash for bool:    fn hash_value(self:
    bool) -> i64:
        if self:
            1
        else:
            0

impl Hash for str:    fn hash_value(self:
    str) -> i64:
        var h: i64 = 1469598103934665603
        var i: i64 = 0
        while i < self.len():
            h = (h *% 1099511628211) ^ self[i]
            i = i + 1
        h

/// Multi-dimensional indexing. Implement to enable `a[i, j]` and slice syntax.
pub trait MultiIndex:    fn multi_index(self: &Self, specs: &[IndexSpec], count:
    i32) -> Self

/// Single-axis read-only indexing (docs/mut.md Rev 8 §2.4).
/// `P[i]` on an `IndexGet`-only type returns a value, not a place — the
/// expression cannot appear on the LHS of an assignment, take a `&raw mut`,
/// or be a mutating-receiver target.
pub trait IndexGet[I, V]:    fn get(self: &Self, index:
    I) -> V

/// Place-projection indexing (docs/mut.md Rev 8 §2.4).
/// `IndexPlace` is a compiler-recognized syntax trait: implementations
/// grant the compiler permission to treat `P[i]` as a place projection of
/// `P`. The compiler lowers reads, writes, and scoped access directly on
/// the underlying storage so that nested place mutation
/// (`xs[i].field = v`, `xs[i].method()`) does not copy the indexed element
/// out and back. The exact contract is implementation-defined and may
/// evolve; the minimal operational shape is value-read + value-write.
pub trait IndexPlace[I, V]:    fn get(self: &Self, index:
    I) -> V
    fn set(mut self: Self, index: I, value: V)

// Vec, Array, and Slice have IndexPlace semantics via the compiler's
// hardcoded place-projection machinery (PK_INDEX in MIR, GEP in codegen).
// Formal `impl IndexPlace for Vec[T]` cannot be added until the compiler
// supports compiling generic trait method bodies — currently MIR validation
// rejects `self[index] = value` for unresolved T.
