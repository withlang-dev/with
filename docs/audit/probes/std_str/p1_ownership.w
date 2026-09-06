use std.string

fn main:
    // T5: concat produces owned copy; mutating source afterwards must not alias
    var a = "foo"
    let b = a ++ "bar"
    a = "CHANGED"
    print(f"concat={b} alen={a.len()} blen={b.len()}")
    // T5: slice is owned copy
    let s = "hello world"
    let sl = s.slice(0, 5)
    print(f"slice={sl} src={s}")
    // T5: split parts are owned copies
    let parts = "a,b,c".split(",")
    print(f"splitlen={parts.len()} p0={parts.get(0)} p2={parts.get(2)}")
    // T5: clone/to_owned independence
    let orig = "clone-me"
    let c = orig.to_owned()
    print(f"clone={c} eq={c == orig}")
    // T5: StringBuilder materialization
    var sb = StringBuilder.new()
    sb.push_str("ab")
    sb.push_byte(99)
    sb.push_char(100)
    let built = sb.to_str()
    print(f"built={built} blen={sb.len()} empty={sb.is_empty()}")
    // T5: repeat/replace/trim/upper/lower owned results
    print(f"rep={"ab".repeat(3)} repl={"aaa".replace("a", "b")} trim={"  x  ".trim()} up={"ab".to_lower().to_upper()} lo={"AB".to_lower()}")
