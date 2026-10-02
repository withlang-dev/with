//! D22-NON-COMPLIANT
//! owner-stage: 5
//! required-verdict: compile-and-run under `--debug-alloc`
//! exact-type: borrowed form returns `&V`; Copy and Clone forms return owned `V`
//! expected-diagnostic: none
//! origin-set: borrowed result preserves its input origin; Copy and Clone results have `{}`
//! drop-behavior: cloned and source Vec buffers each drop exactly once; leak count=0
//! expect-debug-alloc: leak count=0

fn copy_out[V: Copy](value: &V) -> V: value

fn clone_out[V: Clone](value: &V) -> V: value.clone()

fn borrow_or[V](found: Option[&V], fallback: &V) -> &V:
    found ?? fallback

fn main:
    let count = 115
    let count_copy: i32 = copy_out(&count)
    assert(count_copy == 115)

    let source: Vec[i64] = Vec.new()
    source.push(116)
    let cloned: Vec[i64] = clone_out(&source)
    let fallback: Vec[i64] = Vec.new()
    let borrowed: &Vec[i64] = borrow_or(Some(&source), &fallback)
    assert(cloned[0] == 116)
    assert(borrowed[0] == 116)
