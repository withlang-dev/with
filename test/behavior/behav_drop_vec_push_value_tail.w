//! expect-stdout: ok

// [A5] #606: a self-returning mutator (`xs.push`) as the value-returning tail of a
// function declared `-> Vec[W]`. The mutated `xs` is moved out as the return value;
// the local's own drop is cancelled, so the single caller-side owner drops each
// element exactly once.
//
// RULE — what decides whether a self-returning-mutator tail (`...; xs.push(a)`)
// escapes or is dropped locally is the function's declared/contextual return type,
// inferred silently (no user notation):
//   * `-> Vec[W]` (or any context that consumes the value): the tail value is
//     returned and the receiver `xs` is moved out — the *caller* becomes the sole
//     owner and drops the elements exactly once. The local drop is cancelled.
//   * Unit / void context (e.g. the call is a statement, or the helper's result is
//     discarded): the aliasing result does not escape, so `xs` drops its elements
//     locally exactly once.
// With no annotation and a self-returning-mutator tail, the helper's result is the
// receiver Vec; whoever consumes that value (caller capture, discard-drop) owns it,
// and the receiver's local drop is cancelled so the pair drops exactly once. The
// receiver is never double-owned, regardless of which side ends up dropping it.

var COUNT = 0

type W { tag: i32 }
impl Drop for W:
    fn drop(move self: Self):
        COUNT = COUNT + 1

fn make() -> Vec[W]:
    let xs: Vec[W] = Vec.new()
    xs.push(W { tag: 1 })

fn caller():
    let v = make()
    // caller owns the moved-out Vec; `v` drops it exactly once at scope exit.
    let n = v.len()

fn main:
    caller()
    if COUNT == 1:
        print("ok")
    else:
        print_i32(COUNT)
