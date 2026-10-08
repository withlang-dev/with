//! expect-stdout: ab?|ab?|ab?|ab|ab|ab?|abab?|ab|ab!|WARN: slow|cd|cd|none

// D111: a str is a value. Matching on a str, or on a value that carries
// one, observes the subject: a binding copies its part with its own hold,
// the subject keeps its own and stays usable, and every holder drops once
// (the debug allocator run of this test reports a leak or a double free).
enum Msg:
    Text(str)
    Stop

fn opt(s: &str) -> Option[str]:
    if s.len() > 0: Some(s ++ "?") else: None

fn text(m: &Msg) -> str:
    match m:
        .Text(t) => t
        .Stop => "stop"

fn main:
    var line = "a"
    line = line ++ "b"
    let o = opt(&line)
    let f = if let Some(v) = o: v else: "none"
    // let-else over an observed subject: the binding's drop exists only on
    // the success path.
    let Some(g) = o else: return
    let h = match o:
        Some(w) => w
        None => "none"
    let pair = (line, o)
    let (p1, p2) = pair
    let k = match pair:
        (x, Some(y)) => x ++ y
        _ => "no"
    // The whole subject bound by name copies it; `line` keeps its text.
    let b = match line:
        "x" => "lit"
        s => s ++ "!"
    // A regex arm tests the subject in place; the subject's owner drops it.
    var log = "[WARN] slow"
    log = log ++ ""
    let r = match log:
        /^\[(?<level>ERROR|WARN)\]\s+(?<msg>.*)$/ => f"{$level}: {$msg}"
        _ => "missing"
    // A payload binding leaves the carrier whole for the next match.
    let m = Msg.Text("c" ++ "d")
    let c1 = text(&m)
    let c2 = match m:
        .Text(t) => t
        .Stop => "stop"
    let n = if let .Stop = m: "stop" else: "none"
    print(f"{f}|{g}|{h}|{line}|{p1}|{p2 ?? "-"}|{k}|{pair.0}|{b}|{r}|{c1}|{c2}|{n}")
