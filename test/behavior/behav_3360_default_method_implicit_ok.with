//! expect-stdout: ok 4
//! expect-stdout: err -2
//! expect-stdout: done
// #3360: the declared return type is a demand on a default trait method's
// tail as on any function's (§4.9): a value tail under `Result[T, E]` is
// `Ok(tail)`, and falling off a `Result[Unit, E]` body is `Ok(())`. Sema
// accepted the first and recorded no wrap: an ICE in MIR.
type Failed { code: i32 }


trait Sink:
    fn tag(self: &Self) -> i32
    fn checked(self: &Self, n: i32) -> Result[i32, Failed]:
        if n < 0: return Err(Failed { code: n })
        self.tag() + n
        self.tag() + n
    fn finish(self: &Self, n: i32) -> Result[Unit, Failed]:
        if n < 0: return Err(Failed { code: n })
        print("done")

type S { t: i32 }

impl Sink for S:
    fn tag(self: &Self) -> i32: self.t

fn show(r: Result[i32, Failed]):
    match r:
        Ok(v) => print(f"ok {v}")
        Err(e) => print(f"err {e.code}")

fn main:
    let s = S { t: 1 }
    show(s.checked(3))
    show(s.checked(-2))
    assert(s.finish(1).is_ok())
