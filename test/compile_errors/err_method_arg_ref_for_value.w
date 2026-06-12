//! expect-check-fail: wrong argument type

// #567: a &T method argument where plain T is declared must be a
// sema error with a source location — previously it surfaced only as
// a codegen failure naming the enclosing function (or miscompiled).

type Payload { n: i32 }
type Sink { total: i32 }

fn Sink.absorb(mut self: Self, p: Payload) -> i32:
    self.total = self.total + p.n
    self.total

fn main:
    var s = Sink { total: 0 }
    let p = Payload { n: 5 }
    let r = s.absorb(&p)
    print(f"{r}")
