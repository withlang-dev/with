//! expect-stdout: 2 ab 2 6

// #1290: `with expr as mut x:` (§7.2) returns the builder itself, moved
// out; the block must not drop the buffer it is about to return.

type T { id: str }

fn tail_form() -> Vec[i32]:
    with Vec.new() as mut out:
        out.push(1)
        out.push(2)

fn loop_form(count: i32) -> Vec[T]:
    with Vec.new() as mut out:
        for i in 0..count:
            out.push(T { id: f"dev-{i}" })

fn main:
    let v = with Vec.new() as mut v:
        v.push(1)
        v.push(2)
    let s = with "" as mut acc:
        acc = acc ++ "ab"
    print(f"{v.len()} {s} {tail_form().len()} {loop_form(6).len()}")
