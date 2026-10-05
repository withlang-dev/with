// std.traits — trait declarations for the With standard library.
//
// These traits are also registered as builtin trait names in the compiler
// (sema_is_builtin_trait_name), which allows impl blocks to reference them
// even without explicit import. The source definitions here make them
// available through the prelude for documentation and tooling.

// The adapters below (§13.3, #1746) spell Option; a module sees only its
// own imports (§18.2), the core prelude not included.
use std.option

/// Equality comparison (§11.7): `eq` backs `==` and `!=`; a type may
/// override `!=` with `ne`. Both operands are observed.

pub trait Eq:
    fn eq(self: &Self, other: &Self) -> bool

/// Ordering comparison (§11.7): `cmp` backs `<`, `<=`, `>`, `>=`; a type may
/// override any of them with `lt`, `le`, `gt`, `ge`. Both operands are
/// observed. Return negative for less-than, 0 for equal, positive for
/// greater-than.
pub trait Ord:
    fn cmp(self: &Self, other: &Self) -> i32

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
    move fn branch() -> ControlFlow[E, T]
    fn from_break(value: E) -> Self

/// Safe dereference protocol for pointer-like user types. Field and method
/// lookup auto-dereferences through this trait the same way it does through
/// built-in references.
pub trait Deref[T]:
    fn deref(self: &Self) -> &T

/// A key (§11.7, D96): a `HashMap` key or `HashSet` element. Every type
/// whose `==` is structural and that holds no float is one, and the compiler
/// hashes it. A type whose equality is about one part of its value states
/// that part, its key projection, and `==` and the hash both follow from it:
///
///     impl Key for Tag:
///         fn key(): self.name.to_lower()
///
/// `key` returns a key of the type its body gives.
pub trait Key:
    fn key(self: &Self)

/// Debug formatting. Used by `f"{value:?}"` format specifier.
pub trait Debug:
    fn debug_str(self: &Self) -> str

/// Display formatting. Used by `f"{value}"` string interpolation.
pub trait Display:
    fn to_str(self: &Self) -> str

/// Error values expose a display string and an optional underlying cause.
pub trait Error:
    fn display(self: &Self) -> str
    fn source(self: &Self) -> Option[&dyn Error]: None

/// Default value construction. Call `Type.default()` to get the zero value.
pub trait Default:
    fn default() -> Self

/// Cloning. Creates an independent copy of a value.
pub trait Clone:
    fn clone(self: &Self) -> Self

/// Destructor. Called automatically when a value goes out of scope.
/// The receiver is consuming — `move fn` is the only destructor mode (§2.4).
pub trait Drop:
    move fn drop() -> Unit

/// Iterator protocol. Call `.next()` to advance the iterator and return
/// `Option[T]` — `Some(val)` or `None`. The receiver is `mut self: Self`
/// (docs/mut.md Rev 8 §11.1) — the iterator's place is mutated in-place
/// without consuming it, so an iterator bound to a local can be reused
/// across calls. During the bridge phase (P1..P11), `mut self: Self` and
/// consuming `self` produce the same MIR; existing impls written either
/// way continue to satisfy this trait.
pub trait Iter[T]:
    mut fn next() -> Option[T]

/// Generation protocol (§13.4). `each` calls `body` once per element, in
/// order, and stops as soon as `body` returns `false`. Every generator value
/// implements it, and `for x in g:` consumes `g` through `each`.
/// Implementing Gen[T] by hand is library-maintainer work.
pub trait Gen[T]:
    move fn each(body: fn(T) -> bool)

/// Membership test. Implement to enable `x in collection` and
/// `x not in collection`.
pub trait Contains[T]:
    fn contains(self: &Self, value: &T) -> bool

/// Scoped read access protocol used by guarded `with` blocks.
pub trait Scoped[T]:
    fn with_enter(self: &Self) -> T
    fn with_exit(self: &Self) -> Unit

/// Scoped mutable access protocol used by guarded `with ... as mut`.
pub trait ScopedMut[T]:
    fn with_enter_mut(self: &Self) -> T
    mut fn with_exit_mut(value: T) -> Unit

// Core trait impls for primitive types

impl Eq for i32:
    fn eq(other: &i32) -> bool: *self == *other

impl Eq for bool:
    fn eq(other: &bool) -> bool: *self == *other

impl Eq for u8:
    fn eq(other: &u8) -> bool: *self == *other

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

impl Clone for str:
    // Self-contained materialization (`++ ""`): .to_owned() lives in
    // std.string (absent under --no-std) and &str method dispatch to str
    // impls is #762; concat lowers through the emitted intrinsics in
    // every mode.
    fn clone() -> str: self ++ ""

// Primitive clones: generic code (e.g. the SoA derive's row rebuild)
// spells materialization uniformly as .clone(); for Copy primitives the
// clone IS the copy.
impl Clone for i8:   fn clone(): *self
impl Clone for i16:  fn clone(): *self
impl Clone for i32:  fn clone(): *self
impl Clone for i64:  fn clone(): *self
impl Clone for u8:   fn clone(): *self
impl Clone for u16:  fn clone(): *self
impl Clone for u32:  fn clone(): *self
impl Clone for u64:  fn clone(): *self
impl Clone for f32:  fn clone(): *self
impl Clone for f64:  fn clone(): *self
impl Clone for bool: fn clone(): *self

impl Eq for str:
    fn eq(other: &str) -> bool: *self == other

impl Eq for i64:
    fn eq(other: &i64) -> bool: *self == *other

impl Ord for i32:
    fn cmp(other: &i32) -> i32:
        if *self < *other: return -1
        if *self > *other: return 1
        0

impl Ord for i64:
    fn cmp(other: &i64) -> i32:
        if *self < *other: return -1
        if *self > *other: return 1
        0

impl Ord for u8:
    fn cmp(other: &u8) -> i32:
        if *self < *other: return -1
        if *self > *other: return 1
        0

impl Ord for bool:
    fn cmp(other: &bool) -> i32:
        if *self == *other: return 0
        if not *self and *other: return -1
        1

impl Ord for str:
    fn cmp(other: &str) -> i32:
        let value = *self
        var i = 0
        let left_len = value.len()
        let right_len = other.len()
        let limit = if left_len < right_len: left_len else: right_len
        while i < limit:
            let left = value[i]
            let right = other[i]
            if left < right:
                return -1
            if left > right:
                return 1
            i = i + 1
        if left_len < right_len:
            return -1
        if left_len > right_len:
            return 1
        0

impl Debug for i32:
    fn debug_str() -> str: with_i32_to_str(*self)

impl Debug for i64:
    fn debug_str() -> str: with_i64_to_str(*self)

impl Debug for u8:
    fn debug_str() -> str: with_i32_to_str(*self as i32)

impl Debug for bool:
    fn debug_str() -> str:
        if *self:
            "true"
        else:
            "false"

// §15.4.7 / D61: quoted and escaped, exactly as `{s:?}` formats it.
impl Debug for str:
    fn debug_str() -> str: f"{self:?}"

// #1288: §11.8 derives Debug unconditionally, so every primitive a field can
// hold formats. The f-string is the one formatter for every width.
impl Debug for i8:   fn debug_str() -> str: f"{*self}"
impl Debug for i16:  fn debug_str() -> str: f"{*self}"
impl Debug for u16:  fn debug_str() -> str: f"{*self}"
impl Debug for u32:  fn debug_str() -> str: f"{*self}"
impl Debug for u64:  fn debug_str() -> str: f"{*self}"
impl Debug for f32:  fn debug_str() -> str: f"{*self}"
impl Debug for f64:  fn debug_str() -> str: f"{*self}"

// Display for the primitives (§18.2, D55): `print[T: Display]` and any
// other Display bound reach them here; std.builtins imports this module so
// every tier that can call `print` sees them. Each renders exactly as the
// f-string does, so `print(v)` and `print(f"{v}")` agree byte for byte.
impl Display for i8:   fn to_str(): f"{*self}"
impl Display for i16:  fn to_str(): f"{*self}"
impl Display for i32:  fn to_str(): f"{*self}"
impl Display for i64:  fn to_str(): f"{*self}"
impl Display for u8:   fn to_str(): f"{*self}"
impl Display for u16:  fn to_str(): f"{*self}"
impl Display for u32:  fn to_str(): f"{*self}"
impl Display for u64:  fn to_str(): f"{*self}"
impl Display for usize: fn to_str(): f"{*self}"
impl Display for isize: fn to_str(): f"{*self}"
impl Display for f32:  fn to_str(): f"{*self}"
impl Display for f64:  fn to_str(): f"{*self}"
impl Display for bool: fn to_str(): f"{*self}"
impl Display for str:  fn to_str(): self ++ ""

/// Multi-dimensional indexing. Implement to enable `a[i, j]` and slice syntax.
pub trait MultiIndex[O]:
    fn multi_index(self: &Self, specs: &[IndexSpec], count: i32) -> O

/// Mutable multi-dimensional indexing. Implement to enable `a[i, j] = value`
/// and slice assignment syntax.
pub trait MultiIndexMut[V]:
    mut fn multi_index_set(specs: &[IndexSpec], count: i32, value: V) -> Unit

/// Single-axis read-only indexing (docs/mut.md Rev 8 §2.4).
/// `P[i]` on an `IndexGet`-only type returns a value, not a place — the
/// expression cannot appear on the LHS of an assignment, take a `&raw mut`,
/// or be a mutating-receiver target.
pub trait IndexGet[I, V]:
    fn get(self: &Self, index: I) -> V

/// Place-projection indexing (docs/mut.md Rev 8 §2.4).
/// `IndexPlace` is a compiler-recognized syntax trait: implementations
/// grant the compiler permission to treat `P[i]` as a place projection of
/// `P`. The compiler lowers reads, writes, and scoped access directly on
/// the underlying storage so that nested place mutation
/// (`xs[i].field = v`, `xs[i].method()`) does not copy the indexed element
/// out and back. The exact contract is implementation-defined and may
/// evolve; the minimal operational shape is value-read + value-write.
pub trait IndexPlace[I, V]:
    fn get(self: &Self, index: I) -> V
    mut fn set(index: I, value: V)

// Vec, Array, and Slice have IndexPlace semantics via the compiler's
// hardcoded place-projection machinery (PK_INDEX in MIR, GEP in codegen).
// Formal `impl IndexPlace for Vec[T]` cannot be added until the compiler
// supports compiling generic trait method bodies — currently MIR validation
// rejects `self[index] = value` for unresolved T.

// ── Adapters over any Iter[T] (§13.3, #1746) ──────────────────────────────
// The §13.3 operations, written once over the trait: `it.zip(other)`,
// `it.map(f)`, … on a value of any type implementing Iter[T] is Sema's
// call of the free fn of that name here, the receiver first
// (check_user_iter_method). The compiler's built-in iterator types keep
// their intrinsic lowering; these are the one definition for every other
// implementor, std's Pulled[T] included.

/// `a.zip(b)`: pairs until the shorter ends.
pub type Zipped[A, B, L, R] { l: L, r: R }

impl[A, B, L: Iter[A], R: Iter[B]] Iter[(A, B)] for Zipped[A, B, L, R]:
    mut fn next() -> Option[(A, B)]:
        match self.l.next():
            None => None
            Some(x) =>
                match self.r.next():
                    None => None
                    Some(y) => Some((x, y))

pub fn iter_zip[A, B, L: Iter[A], R: Iter[B]](l: L, r: R) -> Zipped[A, B, L, R]: Zipped { l, r }

/// `it.map(f)`: each element through `f`.
pub type Mapped[T, U, I] { inner: I, f: fn(T) -> U }

impl[T, U, I: Iter[T]] Iter[U] for Mapped[T, U, I]:
    mut fn next() -> Option[U]:
        match self.inner.next():
            None => None
            Some(x) => Some((self.f)(x))

pub fn iter_map[T, U, I: Iter[T]](iter: I, f: fn(T) -> U) -> Mapped[T, U, I]: Mapped { inner: iter, f }

/// `it.filter(p)`: the elements for which `p` holds.
pub type Filtered[T, I] { inner: I, pred: fn(&T) -> bool }

impl[T, I: Iter[T]] Iter[T] for Filtered[T, I]:
    mut fn next() -> Option[T]:
        loop:
            match self.inner.next():
                None => return None
                Some(x) =>
                    if (self.pred)(&x):
                        return Some(x)

pub fn iter_filter[T, I: Iter[T]](iter: I, pred: fn(&T) -> bool) -> Filtered[T, I]: Filtered { inner: iter, pred }

/// `it.filter_map(f)`: the `Some`s of `f`.
pub type FilterMapped[T, U, I] { inner: I, f: fn(T) -> Option[U] }

impl[T, U, I: Iter[T]] Iter[U] for FilterMapped[T, U, I]:
    mut fn next() -> Option[U]:
        loop:
            match self.inner.next():
                None => return None
                Some(x) =>
                    match (self.f)(x):
                        None => {}
                        Some(y) => return Some(y)

pub fn iter_filter_map[T, U, I: Iter[T]](iter: I, f: fn(T) -> Option[U]) -> FilterMapped[T, U, I]: FilterMapped { inner: iter, f }

/// `it.take(n)`: the first `n` elements.
pub type Taken[T, I] { inner: I, left: i64 }

impl[T, I: Iter[T]] Iter[T] for Taken[T, I]:
    mut fn next() -> Option[T]:
        if self.left <= 0:
            return None
        self.left -= 1
        self.inner.next()

pub fn iter_take[T, I: Iter[T]](iter: I, n: i64) -> Taken[T, I]: Taken { inner: iter, left: n }

/// `it.drop(n)`: everything after the first `n`.
pub type Dropped[T, I] { inner: I, pending: i64 }

impl[T, I: Iter[T]] Iter[T] for Dropped[T, I]:
    mut fn next() -> Option[T]:
        while self.pending > 0:
            self.pending -= 1
            if self.inner.next().is_none():
                return None
        self.inner.next()

pub fn iter_drop[T, I: Iter[T]](iter: I, n: i64) -> Dropped[T, I]: Dropped { inner: iter, pending: n }

/// `it.take_while(p)`: elements while `p` holds.
pub type TakenWhile[T, I] { inner: I, pred: fn(&T) -> bool, done: bool }

impl[T, I: Iter[T]] Iter[T] for TakenWhile[T, I]:
    mut fn next() -> Option[T]:
        if self.done:
            return None
        match self.inner.next():
            None => None
            Some(x) =>
                if (self.pred)(&x):
                    Some(x)
                else:
                    self.done = true
                    None

pub fn iter_take_while[T, I: Iter[T]](iter: I, pred: fn(&T) -> bool) -> TakenWhile[T, I]: TakenWhile { inner: iter, pred, done: false }

/// `it.drop_while(p)`: elements from the first for which `p` fails.
pub type DroppedWhile[T, I] { inner: I, pred: fn(&T) -> bool, dropping: bool }

impl[T, I: Iter[T]] Iter[T] for DroppedWhile[T, I]:
    mut fn next() -> Option[T]:
        if not self.dropping:
            return self.inner.next()
        loop:
            match self.inner.next():
                None => return None
                Some(x) =>
                    if not (self.pred)(&x):
                        self.dropping = false
                        return Some(x)

pub fn iter_drop_while[T, I: Iter[T]](iter: I, pred: fn(&T) -> bool) -> DroppedWhile[T, I]: DroppedWhile { inner: iter, pred, dropping: true }

/// `it.enumerate()`: `(index, element)` pairs.
pub type Enumerated[T, I] { inner: I, index: i64 }

impl[T, I: Iter[T]] Iter[(i64, T)] for Enumerated[T, I]:
    mut fn next() -> Option[(i64, T)]:
        match self.inner.next():
            None => None
            Some(x) =>
                let i: i64 = self.index
                self.index += 1
                Some((i, x))

pub fn iter_enumerate[T, I: Iter[T]](iter: I) -> Enumerated[T, I]: Enumerated { inner: iter, index: 0 }

/// `a.chain(b)`: all of `a`, then all of `b`.
pub type Chained[T, L, R] { l: L, r: R, first_done: bool }

impl[T, L: Iter[T], R: Iter[T]] Iter[T] for Chained[T, L, R]:
    mut fn next() -> Option[T]:
        if not self.first_done:
            match self.l.next():
                Some(x) => return Some(x)
                None => self.first_done = true
        self.r.next()

pub fn iter_chain[T, L: Iter[T], R: Iter[T]](l: L, r: R) -> Chained[T, L, R]: Chained { l, r, first_done: false }

/// `it.step_by(n)`: every n-th element, starting with the first.
pub type Stepped[T, I] { inner: I, step: i64, started: bool }

impl[T, I: Iter[T]] Iter[T] for Stepped[T, I]:
    mut fn next() -> Option[T]:
        if not self.started:
            self.started = true
            return self.inner.next()
        var skipped: i64 = 1
        while skipped < self.step:
            if self.inner.next().is_none():
                return None
            skipped += 1
        self.inner.next()

pub fn iter_step_by[T, I: Iter[T]](iter: I, n: i64) -> Stepped[T, I]: Stepped { inner: iter, step: n, started: false }

/// `it.fold(init, f)`.
pub fn iter_fold[T, U, I: Iter[T]](iter: I, init: U, f: fn(U, T) -> U) -> U:
    var i = iter
    var acc = init
    while true:
        match i.next():
            None => break
            Some(x) => acc = f(acc, x)
    acc

/// `it.count()`.
pub fn iter_count[T, I: Iter[T]](iter: I) -> i64:
    var i = iter
    var n: i64 = 0
    while i.next().is_some():
        n += 1
    n

/// `it.for_each(f)`.
pub fn iter_for_each[T, I: Iter[T]](iter: I, f: fn(T) -> Unit):
    var i = iter
    while true:
        match i.next():
            None => break
            Some(x) => f(x)

/// `it.any(p)` / `it.all(p)` / `it.none(p)`.
pub fn iter_any[T, I: Iter[T]](iter: I, pred: fn(&T) -> bool) -> bool:
    var i = iter
    while true:
        match i.next():
            None => return false
            Some(x) =>
                if pred(&x):
                    return true
    false

pub fn iter_all[T, I: Iter[T]](iter: I, pred: fn(&T) -> bool) -> bool:
    var i = iter
    while true:
        match i.next():
            None => return true
            Some(x) =>
                if not pred(&x):
                    return false
    true

pub fn iter_none[T, I: Iter[T]](iter: I, pred: fn(&T) -> bool) -> bool: not iter_any(iter, pred)

/// `it.find(p)`: the first element for which `p` holds.
pub fn iter_find[T, I: Iter[T]](iter: I, pred: fn(&T) -> bool) -> Option[T]:
    var i = iter
    while true:
        match i.next():
            None => return None
            Some(x) =>
                if pred(&x):
                    return Some(x)
    None

/// `it.position(p)`: the index of the first element for which `p` holds.
pub fn iter_position[T, I: Iter[T]](iter: I, pred: fn(&T) -> bool) -> Option[i64]:
    var i = iter
    var n: i64 = 0
    while true:
        match i.next():
            None => return None
            Some(x) =>
                if pred(&x):
                    return Some(n)
                n += 1
    None
