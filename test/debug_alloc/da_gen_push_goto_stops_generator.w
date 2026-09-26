//! expect-debug-alloc: leak count=0
//! expect-stdout: defer a
//! expect-stdout: drop a
//! expect-stdout: after goto: a0 a1 a2
//! expect-stdout: defer c
//! expect-stdout: drop c
//! expect-stdout: defer b
//! expect-stdout: drop b
//! expect-stdout: nested: b0c0 b0c1

// D69 (§13.4, #1730): a `goto` out of `for x in g` stops the generator at its
// `yield` like a `break`: its `defer` runs and its owned resource drops once,
// before the label's code — the inner generator first when it leaves nested
// generator loops. The consumer's own owned locals are released on the way.
type Res {
    name: str,
}

impl Drop for Res:
    move fn drop():
        print(f"drop {self.name}")

gen fn items(tag: str, count: i32) -> str:
    let r = Res { name: tag.clone() }
    defer:
        print(f"defer {tag}")
    for i in 0..count:
        let item = f"{tag}{i}"
        yield item
    print(f"done {r.name}")

fn main:
    var seen = ""
    for s in items("a", 10):
        let piece = f" {s}"
        seen = seen ++ piece
        if s == "a2":
            goto 'after_a
    seen = " never"
    'after_a
    print(f"after goto:{seen}")
    var pairs = ""
    for b in items("b", 3):
        for c in items("c", 3):
            pairs = pairs ++ f" {b}{c}"
            if c == "c1":
                goto 'nested_done
    'nested_done
    print(f"nested:{pairs}")
