//! expect-stdout: while 3 51
//! expect-stdout: loop [5!, 6!, 7!, 8!]
//! expect-stdout: labeled got 9|none
//! expect-stdout: ok

// §9.7 (D58), §13.5a, §13.5d, #1733: a `break` in a let-else's else branch
// exits its loop or labeled block like any other `break`. Sema decided
// whether `while true` / `loop` / a labeled block falls through with a walk
// of the syntax that never looked inside a let-else, so it read these loops
// as never exiting: the function's result was never stored (a garbage
// `i32`, an empty leaked `Vec`) and the labeled block typed as `Never`.

fn below(n: i32, lim: i32) -> Option[i32]: if n < lim: Some(n * 10 + 7) else: None

fn count_to(lim: i32) -> i32:
    var n = 0
    var out: Vec[i32] = Vec.new()
    while true:
        let Some(x) = below(n, lim) else: break
        out.push(x)
        n += 1
    var sum = 0
    for v in out: sum += v
    print(f"while {out.len()} {sum}")
    out.len() as i32

fn words_from(start: i32) -> Vec[str]:
    var out: Vec[str] = Vec.new()
    var i = start
    loop:
        let Some(w) = (if i < start + 4: Some(f"{i}!") else: None) else: break
        out.push(w)
        i += 1
    out

fn header(v: Option[i32]) -> str:
    'parse:
        let Some(x) = v else: break 'parse
        return f"got {x}"
    "none"

fn main:
    assert(count_to(3) == 3)
    let ws = words_from(5)
    print(f"loop [{ws.join(", ")}]")
    print(f"labeled {header(Some(9))}|{header(None)}")
    print("ok")
