//! expect-error: cannot assign through a read-only place

// #1007: the retired `set_i32` intrinsic let a read-only `fn` receiver mutate
// a Vec field (twenty MirLower methods and fifty-three more across the
// compiler were declared `fn` while mutating self through it). Element
// assignment is the only spelling now, and it obeys the receiver contract:
// a `fn` receiver is a read-only place (§15.10); mutation is `mut fn`.
type Counter { slots: Vec[i32] }

impl Counter:
    fn poke(i: i32):
        self.slots[i] = 7

fn main:
    var c = Counter { slots: Vec.new() }
    c.slots.push(0)
    c.poke(0)
