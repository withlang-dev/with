//! expect-stdout: ok

// #912: `for x in <generic iterator value>` drives the concrete next()
// specialization — the loop variable gets the substituted element type,
// not a placeholder or the old i32 fallback.

pub type Backwards[T] { items: List[T] }

impl[T] Backwards[T]:
    pub mut fn next() -> Option[T]: self.items.pop()

fn main:
    var v: List[i64] = List.new()
    v.push(41 as i64)
    v.push(42 as i64)
    var it2 = Backwards { items: v }
    var total: i64 = 0
    for x in it2:
        total = total + x
    assert(total == 83)

    // non-generic iterator stays on the same protocol
    var v2: List[str] = List.new()
    v2.push("a")
    v2.push("b")
    var it3 = Backwards { items: v2 }
    var joined = ""
    for s in it3:
        joined = joined ++ s
    assert(joined == "ba")

    // comprehensions drive generic and consuming iterators too (#912)
    var v3: List[i64] = List.new()
    v3.push(1 as i64)
    v3.push(2 as i64)
    var it4 = Backwards { items: v3 }
    let doubled: List[i64] = [x * 2 for x in it4]
    assert(doubled.len() == 2)
    assert(doubled[0] + doubled[1] == 6)
    var v4: List[i32] = List.new()
    v4.push(10)
    let bumped: List[i32] = [x + 1 for x in v4.into_iter()]
    assert(bumped[0] == 11)
    print("ok")
