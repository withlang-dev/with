//! expect-debug-alloc: leak count=0
//! expect-stdout: defer words
//! expect-stdout: drop words
//! expect-stdout: collected w0 w1 w2 w3
//! expect-stdout: defer words
//! expect-stdout: drop words
//! expect-stdout: stopped at w2
//! expect-stdout: defer words
//! expect-stdout: drop words
//! expect-stdout: pairs 4

// D69 (§13.4, §13.6, #1727): a comprehension over a generator moves each
// owned element into the collection, and a `?` in its element stops the
// generator at its `yield` — its defer runs and its resource drops once
// before the function returns the error; the elements collected so far and
// the error's payload are released exactly once.
type Res {
    name: str,
}

impl Drop for Res:
    move fn drop():
        print(f"drop {self.name}")

gen fn words(n: i32) -> str:
    let r = Res { name: "words".clone() }
    defer:
        print("defer words")
    for i in 0..n:
        yield f"w{i}"
    let _ = r.name.len()

fn check(w: &str) -> Result[str, str]:
    if w == "w2": return Err(w.clone())
    Ok(w ++ "!")

fn all_checked() -> Result[Vec[str], str]:
    let v = [check(&w)? for w in words(5)]
    Ok(v)

fn main:
    let v = [w for w in words(4)]
    var text = "collected"
    for w in v:
        text = text ++ " " ++ w
    print(text)
    match all_checked():
        Ok(all) => print(f"no stop {all.len()}")
        Err(e) => print(f"stopped at {e}")
    let pairs = [a ++ b for a in words(2) for b in ["x".clone(), "y".clone()]]
    print(f"pairs {pairs.len()}")
