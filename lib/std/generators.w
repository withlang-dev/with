// std.generators — pipeline stages over Gen[T] (§13.3, §13.4, D69).
//
// A stage that visits elements in order takes any Gen[T] and is itself a
// Gen: `g |> map(f) |> filter(p) |> take(n) |> collect[Vec]()`. A stage
// holds the stage before it as a field, so a pipeline is as lazy as the
// generator it starts from: nothing runs until the last stage is consumed,
// and a stage that has what it needs (take) stops the whole chain by
// answering false. A stage over a generator whose arguments are views holds
// that ephemeral value, so it is ephemeral itself (§5.2, #1737): it is
// consumed where its views are live and never captured by an escaping
// closure (§12.2).
//
// Stages that step a sequence themselves (zip, peekable) take an Iter[T];
// a generator gives one through `g.pull()` (std.task Pulled[T]).

/// `g |> map(f)`: each element of `g` passed through `f`.
pub type MapStage[G, T, U] { g: G, f: fn(T) -> U }

impl[G: Gen[T], T, U] Gen[U] for MapStage[G, T, U]:
    move fn each(body: fn(U) -> bool):
        var me = self
        let map_fn = move me.f
        let source = move me.g
        source.each(x => body(map_fn(x)))

pub fn map[T, U, G: Gen[T]](g: G, f: fn(T) -> U) -> MapStage[G, T, U]: MapStage { g, f }

/// `g |> filter(p)`: the elements of `g` for which `p` holds.
pub type FilterStage[G, T] { g: G, pred: fn(&T) -> bool }

impl[G: Gen[T], T] Gen[T] for FilterStage[G, T]:
    move fn each(body: fn(T) -> bool):
        var me = self
        let keep = move me.pred
        let source = move me.g
        source.each(x => if keep(&x): body(x) else: true)

pub fn filter[T, G: Gen[T]](g: G, pred: fn(&T) -> bool) -> FilterStage[G, T]: FilterStage { g, pred }

/// `g |> take(n)`: the first `n` elements of `g`; the generator stops at the
/// yield of the n-th.
pub type TakeStage[G, T] { g: G, n: i32 }

impl[G: Gen[T], T] Gen[T] for TakeStage[G, T]:
    move fn each(body: fn(T) -> bool):
        var me = self
        let source = move me.g
        take_each(source, me.n, body)

pub fn take[T, G: Gen[T]](g: G, n: i32) -> TakeStage[G, T]: TakeStage { g, n }

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
