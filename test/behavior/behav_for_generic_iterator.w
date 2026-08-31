//! expect-stdout: ok

// #912: `for x in <generic iterator value>` drives the concrete next()
// specialization — the loop variable gets the substituted element type,
// not a placeholder or the old i32 fallback.

type Backwards[T] { items: Vec[T] }

impl[T] Backwards[T]:
    pub mut fn next() -> Option[T]: self.items.pop()

fn main:
    var v: Vec[i64] = Vec.new()
    v.push(41 as i64)
    v.push(42 as i64)
    var it2 = Backwards { items: v }
    var total: i64 = 0
    for x in it2:
        total = total + x
    assert(total == 83)

    // non-generic iterator stays on the same protocol
    var v2: Vec[str] = Vec.new()
    v2.push("a")
    v2.push("b")
    var it3 = Backwards { items: v2 }
    var joined = ""
    for s in it3:
        joined = joined ++ s
    assert(joined == "ba")
    print("ok")
