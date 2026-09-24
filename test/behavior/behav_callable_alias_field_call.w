// §12.4 "The callable type" (D63) + "a binding names what's there": a
// let-bound name for a callable FIELD read through a borrow is an alias of
// that place (the field is not Copy), and calling through the alias calls
// the stored callable — it is not a bare function named `run`. The build
// runner's own compile (build/corpora.w:74, `let prepare =
// corpus.prepare_reference; prepare(...)`) died on this: MirLower read the
// alias ident as a function NAME and emitted a GENERIC_CALL to `run` (#1635).
//! expect-stdout: 42
//! expect-stdout: 21
//! expect-stdout: 126

type Corp { name: str, run: fn(i32) -> i32 }
type Holder { inner: Corp }

fn dbl(x: i32) -> i32: x * 2
fn same(x: i32) -> i32: x

fn through_borrow(c: &Corp) -> i32:
    let run = c.run
    run(21)

fn through_owned(c: Corp) -> i32:
    let run = c.run
    run(21)

fn nested(h: &Holder) -> i32:
    let run = h.inner.run
    run(21) + h.inner.run(21) + h.inner.run.clone()(21)

fn main:
    let a = Corp { name: "a", run: dbl }
    print(through_borrow(&a))
    print(through_owned(Corp { name: "b", run: same }))
    print(nested(&Holder { inner: a }))
