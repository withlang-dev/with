//! expect-stdout: ok

// D11 (§18.6): len() is signed Int (i64) on every collection — never usize,
// never Option. The empty-collection idioms that used to trap or need casts
// just work: len()-1 is -1, countdowns run without wrapping, and len() feeds
// i64 indexing directly.

fn main:
    let empty: Vec[i32] = Vec.new()
    assert(empty.len() - 1 == -1)

    let s = ""
    assert(s.len() - 1 == -1)

    var m: HashMap[str, i32] = HashMap.new()
    assert(m.len() - 1 == -1)

    let bset: BTreeSet[i32] = [3, 1, 2]
    assert(bset.len() == 3)
    let bmap: BTreeMap[str, i32] = ["a": 1, "b": 2]
    assert(bmap.len() - 3 == -1)

    // The countdown idiom: no casts, no wrap, index feeds get() directly.
    var v: Vec[i32] = Vec.new()
    v.push(1)
    v.push(2)
    v.push(3)
    var i = v.len() - 1
    var sum = 0
    while i >= 0:
        sum = sum + v[i]
        i = i - 1
    assert(sum == 6)
    assert(v[v.len() - 1] == 3)

    // The declared type is Int (i64).
    let n: Int = v.len()
    let n64: i64 = v.len()
    assert(n == 3 and n64 == 3)

    print("ok")
