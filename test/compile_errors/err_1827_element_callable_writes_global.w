//! expect-check-fail: mutates global `G` while `r` is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rule 1): a callable stored in a
// List and called through its element runs any callable value of its type in
// this compilation; the closure pushed onto `fs` reallocates `G` while `r`
// views its first element.
var G: List[str] = List.new()

fn main:
    G.push("first" ++ "!")
    var fs: List[fn() -> Unit] = List.new()
    fs.push(move () => { for i in 0..64: G.push(f"item{i}") })
    let r = G[0]
    fs[0]()
    print(r)
