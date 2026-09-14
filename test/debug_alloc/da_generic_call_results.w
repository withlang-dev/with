//! expect-debug-alloc: leak count=0

global var result_drops = 0

type ResultGuard { text: str }
impl Drop for ResultGuard:
    move fn drop(): result_drops += 1

type Producer[T] { value: T }
impl[T] Producer[T]:
    move fn take():
        var owner = self
        move owner.value

fn identity[T](value: T): value
fn accept(value: ResultGuard): assert(value.text == "owned")

fn exercise:
    identity(ResultGuard { text: "discarded".clone() })
    assert(result_drops == 1)
    Producer { value: ResultGuard { text: "discarded method".clone() } }.take()
    assert(result_drops == 2)
    for i in 0..3:
        Producer { value: ResultGuard { text: "loop".clone() } }.take()
    assert(result_drops == 5)
    accept(identity(ResultGuard { text: "owned".clone() }))
    assert(result_drops == 6)
    let retained = Producer { value: ResultGuard { text: "retained".clone() } }.take()
    assert(retained.text == "retained")
    assert(result_drops == 6)

fn main:
    exercise()
    assert(result_drops == 7)
