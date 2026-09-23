//! expect-stdout: old,new,drop
//! expect-stdout: 3

// §9.1 / D60: under a `Unit` return — declared, or a trait's contract such
// as `Drop.drop` — nothing is returned, so an assignment ending a nested
// block of the body is a statement too: a global `str` it assigns is not
// read back (no D52 move-out-of-global error), and a Copy one is untouched.

var trace: str = ""
var count: i32 = 0

type Tracer { id: str }

impl Drop for Tracer:
    fn drop(move self: Self):
        {
            trace = trace ++ self.id
        }

fn note(s: &str) -> Unit:
    {
        trace = trace ++ s ++ ","
    }

fn bump:
    {
        count += 3
    }

fn scoped_tracer:
    let t = Tracer { id: "drop".clone() }
    assert(t.id == "drop")

fn main:
    note("old")
    note("new")
    scoped_tracer()
    bump()
    print(trace)
    print(count)
