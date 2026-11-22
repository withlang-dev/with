//! expect-debug-alloc: leak count=0
//! expect-stdout: [alpha]
//! expect-stdout: [alpha] [al] [pha]

// #2307 (D111): a str stored from a `&str` view owns its bytes. The view
// here is an interior slice of a temporary (`slice` then `trim`), freed at
// the end of its statement; the str copies it rather than sharing a buffer
// it does not hold. The same-sized allocations after it would reuse a freed
// buffer and overwrite what a dangling str reads.
fn main:
    let text = "  asset: " ++ "alpha\n  other\n  sha: x"
    let lines = text.split("\n")
    var pending = ""
    for i in 0..lines.len():
        let line = lines[i]
        let at = line.index_of("asset:")
        if at >= 0: pending = line.slice(at + 6, line.len()).trim()
    var junk: List[str] = []
    for k in 0..64: junk.push(f"zzzzzzzzzzzzzz{k}")
    print(f"[{pending}]")
    let whole = "alpha" ++ ""
    let prefix: str = whole[0..2]
    let tail: str = whole[2..5]
    print(f"[{whole}] [{prefix}] [{tail}]")
