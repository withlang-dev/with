//! expect-stdout: ok

// D12 (§9.5): the receiver MODE decides share-place, not the owner's type.
// A `mut fn` on a scalar primitive owner borrows and mutates the CALLER's
// place — `x.bump()` mutates `x` — while `f(x)` still copies (Copy). The
// distinct/newtype domain-verb idiom mutates in place through the same
// share-place ABI.

type Health = distinct i32

extend i32:
    mut fn bump(): self += 1
    mut fn double(): self *= 2

extend Health:
    mut fn damage(n: i32): self = Health(self.value - n)
    mut fn heal(n: i32): self = Health(self.value + n)

// A by-value copy: the callee mutates its own place, never the caller's.
fn bump_a_copy(x: i32) -> i32:
    var y = x
    y.bump()
    y

fn main:
    // Straight line: mutation reaches the caller.
    var x: i32 = 10
    x.bump()
    assert(x == 11)
    x.double()
    assert(x == 22)

    // f(x) copies — the callee's mutation of its copy cannot touch the
    // caller (D12: mode wins; the plain param has no mode).
    assert(bump_a_copy(x) == 23)
    assert(x == 22)

    // Branch and loop shapes drive the same place.
    var n: i32 = 0
    for i in 0..5:
        if i % 2 == 0:
            n.bump()
    assert(n == 3)

    // Distinct/newtype domain verbs (spec §9.5 idiom).
    var hp = Health(100)
    hp.damage(30)
    assert(hp.value == 70)
    hp.heal(5)
    assert(hp.value == 75)

    // f64 and bool owners take the same path.
    var f = 1.5
    f.fdouble()
    assert(f == 3.0)
    var b = false
    b.flip()
    assert(b)

    print("ok")

extend f64:
    mut fn fdouble(): self *= 2.0

extend bool:
    mut fn flip(): self = not self
