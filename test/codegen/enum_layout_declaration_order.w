//! expect-stdout: enum 32 32 model 32 32
//! expect-stdout: inner 24 24 model 24 24
//! expect-stdout: nested 48 48
//! expect-stdout: generic 40 40
//! expect-stdout: disc-field 16 16
//! expect-stdout: disc-payload 24 24
//! expect-stdout: aligned 64 64
//! expect-stdout: ok

// #1430 (docs/spec/abi/with-abi.md §2): declaration order never changes a layout. Each
// Late* type is declared before the types it holds by value, each Early* type
// after them; the pairs are otherwise identical and must lay out identically.
// Codegen used to size a Late* payload from a bodiless placeholder (0 bytes):
// LateOuter measured 12 bytes, LateRec 8, LateAligned 16. The §2 enum layout
// is a 4-byte tag followed by the largest variant's fields laid out as a
// struct at that payload's own alignment, the enum aligned to the larger of
// the two (#1438: `B(a: i32, b: i64)` puts its 16-byte, 8-aligned payload at
// offset 8, so LateInnerE is 24 bytes, not 20), so the sizes are pinned too,
// and the layout model Sema answers `T.size()` from (TypeLayout) is what the
// LLVM type codegen emits measures.

// Sema does not yet resolve a generic declared after its user (a separate
// issue), so the template comes first; its instantiation is still Late.
enum Gen[T]:
    Of(t: T)
    Nothing

enum LateOuter:
    E(e: LateInnerE)
    S(s: LateInner, k: i64)

enum LateTop:
    X(m: LateOuter, t: i64)
    Nil

enum LateGeneric:
    G(g: Gen[LateInner], k: i64)
    Nil

type LateRec { k: LateKind, n: i64 }

enum LateMsg: i32:
    Quit = 0
    Move(p: LateInner) = 1

type LateAligned {
    a: i8,
    @[align(16)]
    inner: LateInner,
    e: LateInnerE,
}

type LateInner { x: i64, y: i64 }

enum LateInnerE:
    A(n: i32)
    B(a: i32, b: i64)

enum LateKind: i32:
    Red = 1
    Blue = 2

type EarlyInner { x: i64, y: i64 }

enum EarlyInnerE:
    A(n: i32)
    B(a: i32, b: i64)

enum EarlyKind: i32:
    Red = 1
    Blue = 2

enum EarlyOuter:
    E(e: EarlyInnerE)
    S(s: EarlyInner, k: i64)

enum EarlyTop:
    X(m: EarlyOuter, t: i64)
    Nil

enum EarlyGeneric:
    G(g: Gen[EarlyInner], k: i64)
    Nil

type EarlyRec { k: EarlyKind, n: i64 }

enum EarlyMsg: i32:
    Quit = 0
    Move(p: EarlyInner) = 1

type EarlyAligned {
    a: i8,
    @[align(16)]
    inner: EarlyInner,
    e: EarlyInnerE,
}

const MODEL_LATE_OUTER: usize = comptime LateOuter.size()
const MODEL_EARLY_OUTER: usize = comptime EarlyOuter.size()
const MODEL_LATE_INNER: usize = comptime LateInnerE.size()
const MODEL_EARLY_INNER: usize = comptime EarlyInnerE.size()

fn main:
    print(f"enum {size_of[LateOuter]()} {size_of[EarlyOuter]()} model {MODEL_LATE_OUTER} {MODEL_EARLY_OUTER}")
    print(f"inner {size_of[LateInnerE]()} {size_of[EarlyInnerE]()} model {MODEL_LATE_INNER} {MODEL_EARLY_INNER}")
    print(f"nested {size_of[LateTop]()} {size_of[EarlyTop]()}")
    print(f"generic {size_of[LateGeneric]()} {size_of[EarlyGeneric]()}")
    print(f"disc-field {size_of[LateRec]()} {size_of[EarlyRec]()}")
    print(f"disc-payload {size_of[LateMsg]()} {size_of[EarlyMsg]()}")
    print(f"aligned {size_of[LateAligned]()} {size_of[EarlyAligned]()}")
    print("ok")
