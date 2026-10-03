// D22: arithmetic on a &T view operand materializes the operand and produces
// an owned T. The MIR fallback type for `view + int` must be the element type,
// never the reference type — a ref-typed result made call-arg lowering deref
// the already-owned sum (double contextual-copy deref, garbage index).
// Repro shape: AstPool.get_call_named_arg (map get → unwrap view → sum →
// call argument in return position).

type T {
    m: HashMap[i32, i32],
    extra: Vec[i32],
}

impl T:
    fn extra_at(i: i32) -> i32:
        self.extra[i]

    fn lookup(k: i32, idx: i32) -> i32:
        if self.m.contains(k):
            let start = self.m.get(k).unwrap()
            return self.extra_at(start + idx)
        0

    fn lookup_sub(k: i32, idx: i32) -> i32:
        if self.m.contains(k):
            let start = self.m.get(k).unwrap()
            return self.extra_at(start - idx)
        0

    fn lookup_neg(k: i32) -> i32:
        if self.m.contains(k):
            let start = self.m.get(k).unwrap()
            return self.extra_at(0 - (0 - start))
        0

fn main:
    var t = T { m: HashMap.new(), extra: Vec.new() }
    t.m.insert(7, 2)
    t.extra.push(10)
    t.extra.push(20)
    t.extra.push(30)
    t.extra.push(40)
    assert(t.lookup(7, 1) == 40)
    assert(t.lookup_sub(7, 1) == 20)
    assert(t.lookup_neg(7) == 30)

    // Two-view arithmetic: both operands materialize; the sum is owned.
    let a = t.m.get(7).unwrap()
    let b = t.m.get(7).unwrap()
    assert(t.extra_at(a + b - 1) == 40)
    print("ok")
