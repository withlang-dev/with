//! expect-stdout: a -> b
//! expect-stdout: b -> c
//! expect-stdout: first
//! expect-stdout: name: who

// #3026 (D111, D179): a str is a value, so an unannotated `let` of a str
// place — a field of self, a field of a local record, a global — takes the
// str (a count increment), never a view of the place. A later write to the
// owner, a consume of the record, or a read of the global as a value
// needs no `.clone()` and no `: str` annotation.
type Rec { name: str, n: i32 }
impl Rec:
    mut fn rename(mut self, to: str):
        let old = self.name
        self.name = to
        print(f"{old} -> {self.name}")

var g_label: str = "first"

fn label() -> str:
    g_label

fn keep(r: Rec) -> i32: r.n

fn main:
    var r = Rec { name: "a", n: 1 }
    r.rename("b")
    r.rename("c")
    print(label())
    let who = Rec { name: "who", n: 2 }
    let name = who.name
    let n = keep(who)
    print(f"name: {name}")
    assert(n == 2)
