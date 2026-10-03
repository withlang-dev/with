//! expect-stdout: ok

// #719: the __with_init_const_* lowering flushed pending reset-on-move
// blanks from index 0 of the statement frame, so a const struct pairing a
// Vec field with a following HashMap move had its Vec zeroed before the
// struct was built. The mixed {Vec, HashMap} shape is the one cell of the
// matrix that failed; keep it pinned.

type P { values: Vec[i32], table: HashMap[str, i32] }

comptime fn build() -> P:
    var v = Vec[i32].new()
    v.push(4)
    var t = HashMap[str, i32].new()
    t.insert("left", 11)
    P { values: v, table: t }

const PK: P = comptime build()

fn main:
    assert(PK.values[0] == 4)
    assert(PK.table.get("left").unwrap() == 11)
    print("ok")
