//! expect-stdout: 3 -1 5 0
//! expect-stdout: [x  ] [  x] [] [x]
//! expect-stdout: 104 105 2
//! expect-stdout: a:b:c -> a:b | c

// #2206: the str conveniences a one-liner reaches for. `rfind` is `find`
// from the other end (-1 when absent; an empty needle is found at the
// end); `trim_start`/`trim_end` are views past leading / before trailing
// ASCII whitespace; `bytes()` iterates the bytes.
fn main:
    let path = "a:b:c"
    print(f"{path.rfind(":")} {path.rfind("z")} {path.rfind("")} {"aaa".rfind("aaa")}")
    let padded = "  x  "
    let tail: &str = padded.trim_start()
    let head: &str = padded.trim_end()
    print(f"[{tail}] [{head}] [{"   ".trim_start()}] [{"x".trim_end()}]")
    var count = 0
    var line = ""
    for b in "hi".bytes():
        line = line ++ f"{b} "
        count += 1
    print(f"{line}{count}")
    let cut = path.rfind(":")
    print(f"{path} -> {path[0..cut]} | {path[cut + 1..path.len()]}")
