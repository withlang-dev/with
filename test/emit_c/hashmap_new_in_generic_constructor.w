//! expect-stdout: 9
//! expect-stdout: 1

// A map built by `HashMap.new()` inside a generic constructor takes its key
// and value types from its destination's MIR type in the C backend, as in
// the LLVM one. The C backend read a usage hint that missed the generic
// instance and fell back to an i64 key: a `HashMap[i32, i64]` hashed
// 8-byte keys it was given 4 of, and every lookup missed.
use std.collections.HashMap

type Wrap[T] { value: T }

fn Wrap.new[T](v: T) -> Wrap[T]: Wrap { value: v }

type Table[K, V] { cell: Wrap[HashMap[K, V]] }

fn Table.new[K, V]() -> Table[K, V]:
    Table { cell: Wrap.new(HashMap.new()) }

fn main:
    var t: Table[i32, i64] = Table.new()
    t.cell.value.insert(1, 9)
    print(t.cell.value.get(1) ?? 0)
    print(t.cell.value.len())
