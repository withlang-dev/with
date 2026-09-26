//! expect-debug-alloc: leak count=0
//! expect-stdout: first k0
//! expect-stdout: defer k
//! expect-stdout: drop k-res
//! expect-stdout: unconsumed: nothing ran
//! expect-stdout: drop u
//! expect-stdout: defer owner
//! expect-stdout: drop owner
//! expect-stdout: moved receiver stopped at owner-1
//! expect-stdout: defer borrowed
//! expect-stdout: borrowed receiver stopped at borrowed-0, still here
//! expect-stdout: drop borrowed

// D69 (§13.4, #1724): a generic generator stopped early runs its defer and
// drops the argument it owns once; a generic generator value never consumed
// drops only its arguments. A `move` receiver is an argument the generator
// owns, released when the stopped generator leaves; a borrowed receiver
// stays the caller's, released once at the caller's scope end.
type Res {
    name: str,
}

impl Drop for Res:
    move fn drop():
        print(f"drop {self.name}")

gen fn tagged[T](x: T, tag: str) -> str:
    defer:
        print(f"defer {tag}")
    for i in 0..5:
        yield f"{tag}{i}"

impl Res:
    gen move fn parts() -> str:
        defer:
            print(f"defer {self.name}")
        for i in 0..4:
            yield f"{self.name}-{i}"
    gen fn peek_parts() -> str:
        defer:
            print(f"defer {self.name}")
        for i in 0..4:
            yield f"{self.name}-{i}"

fn generic_stop():
    for s in tagged(Res { name: "k-res".clone() }, "k".clone()):
        print(f"first {s}")
        break

fn generic_unconsumed():
    let unused = tagged(Res { name: "u".clone() }, "never".clone())
    print("unconsumed: nothing ran")

fn moved_receiver():
    let owner = Res { name: "owner".clone() }
    var last = ""
    for p in owner.parts():
        last = p.clone()
        if p == "owner-1":
            break
    print(f"moved receiver stopped at {last}")

fn borrowed_receiver():
    let borrowed = Res { name: "borrowed".clone() }
    var first = ""
    for p in borrowed.peek_parts():
        first = p.clone()
        break
    print(f"borrowed receiver stopped at {first}, still here")

fn main:
    generic_stop()
    generic_unconsumed()
    moved_receiver()
    borrowed_receiver()
