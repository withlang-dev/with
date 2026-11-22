// D39 emitter refusal fixture (§21.1 rule 6, spec v7.18): at a bundle
// boundary an absent `from` clause means the elision — the receiver, else
// the single borrowed parameter. `pick` has a receiver but returns a view of
// `o`, so it must state `from o`, or a consumer would tie the result to the
// receiver.
pub type Pair { a: i32, b: i32 }
impl Pair:
    pub fn pick(o: &Pair) -> &i32: &o.a
