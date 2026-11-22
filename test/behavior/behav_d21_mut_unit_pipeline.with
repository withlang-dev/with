//! expect-stdout: ok

type Counter { n: i32 }

impl Counter:
    mut fn add(amount: i32): self.n += amount

    mut fn add_and_report(amount: i32) -> bool:
        self.n += amount
        true

fn accepts_unit(_value: Unit):
    let _ = _value

fn free_unit_stage(_value: Counter) -> Unit:
    return

fn main:
    var c = Counter { n: 0 }
    c |> add(1) |> add(2)
    assert(c.n == 3)

    accepts_unit(c.add(4))
    assert(c.n == 7)

    let reported = c |> add_and_report(5)
    assert(reported)
    assert(c.n == 12)

    // Free-function pipelines keep the ordinary return-value law. Unit does
    // not become a receiver carrier unless the resolved callee is a mut method.
    accepts_unit(c |> free_unit_stage())
    assert(c.n == 12)

    let built = Counter { n: 10 } |> add(20) |> add(12)
    assert(built.n == 42)
    print("ok")
