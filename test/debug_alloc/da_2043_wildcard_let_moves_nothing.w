//! expect-debug-alloc: leak count=0
//! expect-stdout: 2 2 ab

// D5/P1: `let _ = x` does not bind or move `x` (Sema's rule: x stays
// usable). MirLower moved it into a discard local anyway, so the next read
// saw the reset-on-move blank: `let _ = h; h.len()` returned 0, and the
// ownership validator (now run on every build, #2043) reported "move of _1,
// which a path reaching it already moved out" in rt/cimport_stubs.w.
type Holder {
    s: str,
}

fn len_after_discard(h: str) -> i64:
    let _ = h
    h.len()

fn field_after_discard(o: Holder) -> i64:
    let _ = o.s
    o.s.len()

fn main:
    let a = len_after_discard("ab".clone())
    let b = field_after_discard(Holder { s: "cd".clone() })
    let kept = "ab".clone()
    let _ = kept
    print(f"{a} {b} {kept}")
