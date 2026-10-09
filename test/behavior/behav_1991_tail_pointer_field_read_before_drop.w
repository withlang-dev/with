//! expect-stdout: 7
//! expect-stdout: true
// A block tail that copies a raw-pointer field through an element place of
// a local the block drops (`let t = rows(); t[i].p`) reads before the
// scope-exit drop, as a non-pointer field does (#1968): a raw pointer is a
// value, not a view of the place. Before the fix the read was left lazy
// for TY_PTR, scheduled after `drop(t)`, and saw the freed List ("index out
// of bounds").

type Row { p: *const i32, n: i32 }

fn rows(target: *const i32) -> List[Row]:
    let t: List[Row] = List.new()
    t.push(Row { p: target, n: 7 })
    t

fn n_tail(target: *const i32) -> i32:
    let t = rows(target)
    t[0].n

fn p_tail(target: *const i32) -> *const i32:
    let t = rows(target)
    t[0].p

fn main:
    let value = 42
    let target = &raw const value
    print(n_tail(target))
    print(p_tail(target) == target)
