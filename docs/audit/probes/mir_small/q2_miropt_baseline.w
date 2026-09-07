type Rec {
    value: i32,
    tag: i32,
}

fn main:
    let r = Rec { value: 40, tag: 2 }
    let f = (x: i32) => x + 2
    let m = r.value
    let v = f(m)
    assert(v == 42)
    assert(r.tag == 2)
    // `tag` is never read before this point: it is exactly the shape a
    // naive dead-field eliminator (read_count == 0) would delete, and `m`
    // is the shape a naive move-elider would rewrite. Both must survive.
    print(f"v={v} tag={r.tag}")
