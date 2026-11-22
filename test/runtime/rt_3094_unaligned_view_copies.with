//! expect-stdout: 0:shares
//! expect-stdout: 1:copies 2:copies 3:copies 4:copies 5:copies 6:copies 7:copies
//! expect-stdout: lines intact
// #3094 (#3095): `line.trim()` is a view into the line's block; binding it
// owns the view through with_str_own_view. A view that starts the block's
// payload shares the block (offset 0). A view inside it is copied, whatever
// the bytes before it read as: the reproducer was offset 7, where the
// bytes before the view are the block header's `size` byte 7 and `holders`
// = 1, read as the i64 256, a size class, so the runtime took the view for
// a block start and counted a holder in the header. An unaligned pointer
// is never a block start now, and the slab's block map decides for aligned
// ones. The holders word must stay 1, so every line prints back intact.
use rt.rt_core
use std.process

fn data_ptr(s: &str) -> i64: unsafe *(&raw const *s as *const i64)

fn main:
    var text = args()[0].slice(0, 0)
    var pad = ""
    for k in 0..8:
        text = text ++ pad ++ "bb_count != body.bb_term_d1.len() or the rest of a line\n"
        pad = pad ++ " "
    var verdicts = ""
    var intact = true
    var k = 0
    for line in text.split("\n"):
        if line.len() == 0: continue
        let base = data_ptr(line)
        let t = line.trim()
        let verdict = if data_ptr(t) == base + k: "shares" else: "copies"
        verdicts = verdicts ++ (if verdicts.len() == 0: "" else: " ") ++ f"{k}:{verdict}"
        if k == 0:
            print(verdicts)
            verdicts = ""
        if not line.ends_with("the rest of a line") or t != "bb_count != body.bb_term_d1.len() or the rest of a line": intact = false
        k = k + 1
    print(verdicts)
    print(if intact: "lines intact" else: "lines changed")
