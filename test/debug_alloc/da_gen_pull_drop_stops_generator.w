//! expect-debug-alloc: leak count=0
//! expect-stdout: got a0 a1
//! expect-stdout: defer a
//! expect-stdout: drop a
//! expect-stdout: after early drop
//! expect-stdout: defer b
//! expect-stdout: drop b
//! expect-stdout: ran out: b0 b1 b2
//! expect-stdout: unstarted: nothing ran
//! expect-stdout: moved: c0
//! expect-stdout: defer c
//! expect-stdout: drop c

// D69 (§13.4 Pulling): dropping a pulled generator before its end stops it
// exactly as a consumer's `break` does — it leaves at its `yield`, its defer
// runs and its owned resource drops once, before the drop returns. One run
// to its end releases them once too; one never stepped never ran and
// releases only its arguments; one moved into a struct is stopped where the
// struct drops. The fiber stack and its bookkeeping are released each time.
use std.task.Pulled

type Res {
    name: str,
}

impl Drop for Res:
    move fn drop():
        print(f"drop {self.name}")

gen fn items(tag: str, count: i32) -> str:
    let r = Res { name: tag.clone() }
    defer:
        print(f"defer {r.name}")
    for i in 0..count:
        yield f"{tag}{i}"

type Holder {
    seq: Pulled[str],
}

fn early():
    var p = items("a".clone(), 5).pull()
    let x = p.next().unwrap()
    let y = p.next().unwrap()
    print(f"got {x} {y}")

fn to_end():
    var p = items("b".clone(), 3).pull()
    var seen = ""
    while true:
        match p.next():
            Some(s) => seen = if seen.len() == 0: s else: seen ++ " " ++ s
            None => break
    print(f"ran out: {seen}")

fn unstarted():
    let p = items("u".clone(), 3).pull()
    let _ = p
    print("unstarted: nothing ran")

fn moved():
    var h = Holder { seq: items("c".clone(), 4).pull() }
    print(f"moved: {h.seq.next().unwrap()}")

fn main:
    early()
    print("after early drop")
    to_end()
    unstarted()
    moved()
