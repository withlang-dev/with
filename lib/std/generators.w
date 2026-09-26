// std.generators — pipeline stages over Gen[T] (§13.3, §13.4, D69).
//
// A stage that visits elements in order takes any Gen[T] and is itself a
// Gen: `g |> map(f) |> filter(p) |> take(n) |> collect[Vec]()`. A stage owns
// the stage before it inside the callable that runs it, so a pipeline is as
// lazy as the generator it starts from: nothing runs until the last stage is
// consumed, and a stage that has what it needs (take) stops the whole chain
// by answering false.
//
// Stages that step a sequence themselves (zip, peekable) take an Iter[T];
// a generator gives one through `g.pull()` (#1725).

/// A pipeline stage: the Gen[T] that `run` produces when it is handed the
/// consumer's body.
pub type GenStage[T] {
    run: fn(fn(T) -> bool) -> Unit,
}

impl[T] Gen[T] for GenStage[T]:
    move fn each(body: fn(T) -> bool): (self.run)(body)

/// `g |> map(f)`: each element of `g` passed through `f`.
pub fn map[T, U](g: impl Gen[T], f: fn(T) -> U) -> GenStage[U]:
    GenStage { run: move (body: fn(U) -> bool) => g.each(x => body(f(x))) }

/// `g |> filter(p)`: the elements of `g` for which `p` holds.
pub fn filter[T](g: impl Gen[T], pred: fn(&T) -> bool) -> GenStage[T]:
    GenStage { run: move (body: fn(T) -> bool) => g.each(x => if pred(&x): body(x) else: true) }

/// `g |> take(n)`: the first `n` elements of `g`; the generator stops at the
/// yield of the n-th.
pub fn take[T](g: impl Gen[T], n: i32) -> GenStage[T]:
    GenStage { run: move (body: fn(T) -> bool) => take_each(g, n, body) }

fn take_each[T](g: impl Gen[T], n: i32, body: fn(T) -> bool):
    if n <= 0:
        return
    var left = n
    g.each(x => {
        left -= 1
        body(x) and left > 0
    })

/// `g |> collect[Vec]()`: every element of `g`, in order.
pub fn collect[T](g: impl Gen[T]) -> Vec[T]:
    var out: Vec[T] = Vec.new()
    g.each(x => {
        out.push(x)
        true
    })
    out
