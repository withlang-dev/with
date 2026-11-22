//! expect-stdout: [alpha]
//! expect-stdout: [beta]
//! expect-stdout: [gamma]
//! expect-stdout: [delta]
//! expect-stdout: [field]

// #2366: assigning a view of a variable back to that variable makes the
// new value before the old one is freed. `s = s.trim()` stored a `&str`
// into s's own buffer after the overwrite drop had freed it: the program
// printed NUL bytes where the text had been, with no error and exit 0.
// The buffers are grown past their literals so the drop really frees.

fn grown(text: &str) -> str:
    var out = ""
    out = out ++ "  " ++ text ++ "  "
    out

fn main:
    var s = grown("alpha")
    s = s.trim()
    print(f"[{s}]")

    var t = grown("beta")
    t = t.trim_start()
    t = t.trim_end()
    print(f"[{t}]")

    var u = grown("gamma")
    let v = u.trim()
    u = v
    print(f"[{u}]")

    // The old value is still read on the way in: a loop that re-trims.
    var w = grown("delta")
    for _ in 0..3:
        w = w.trim()
    print(f"[{w}]")

    // A copy through a field of the destination's own record.
    var pair = (grown("field"), 0)
    var p0 = pair.0
    p0 = p0.trim()
    print(f"[{p0}]")
