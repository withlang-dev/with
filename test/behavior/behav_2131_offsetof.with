//! expect-stdout: 0 8 16 24
//! expect-stdout: 0 4 8
//! expect-stdout: 0 8 16

// D109 (#2131): `offsetof[T](field)` is the field's byte offset in T's
// layout. The migrated pcre2 carried clang's host-folded
// `offsetof(heapframe, ovector)` (136, a 64-bit layout) onto wasm32, where
// every frame field was then addressed askew and every match failed; the
// builtin lets the migrator leave the offset to the target.

type Padded { a: u8, b: i64, c: u8, d: i64 }
type Pair[T] { first: T, second: T }
type Mixed { tag: i32, pair: Pair[i64] }

fn main:
    print(f"{offsetof[Padded](a)} {offsetof[Padded](b)} {offsetof[Padded](c)} {offsetof[Padded](d)}")
    print(f"{offsetof[Pair[i32]](first)} {offsetof[Pair[i32]](second)} {sizeof[Pair[i32]]()}")
    print(f"{offsetof[Mixed](tag)} {offsetof[Mixed](pair)} {offsetof[Mixed](pair) + offsetof[Pair[i64]](second)}")
