//! expect-debug-alloc: leak count=0
//! expect-stdout: hello 3
//! expect-stdout: drop outer
//! expect-stdout: consumed inner
//! expect-stdout: drop inner
//! expect-stdout: drop q
//! expect-stdout: drop pa

// #983: the C backend runs every destructor the LLVM backend does — a
// type's Drop impl, then its remaining fields in reverse — and frees what
// it owns. A field a Drop body moves out is blanked in the owner's storage
// (the receiver is the owner's place), so the field cleanup after the body
// skips it. A moved-from local is the reset sentinel and drops nothing.
type Noisy:
    name: str

impl Drop for Noisy:
    move fn drop():
        print(f"drop {self.name}")

type Pair:
    a: Noisy
    b: List[str]

type Outer:
    inner: Noisy
    tag: str

impl Drop for Outer:
    move fn drop():
        print("drop outer")
        consume(self.inner)

fn consume(n: Noisy):
    print(f"consumed {n.name}")

fn make(n: &str) -> Noisy: Noisy { name: n.clone() }

fn main:
    let x = make("q")
    var p = Pair { a: make("pa"), b: ["one", "two"] }
    p.b.push("three")
    let q = x
    print(f"hello {p.b.len()}")
    let o = Outer { inner: make("inner"), tag: "t" ++ q.name }
    drop(o)
