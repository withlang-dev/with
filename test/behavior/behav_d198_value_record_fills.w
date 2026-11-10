//! expect-stdout: 3 4 | 0 7 7 | 9 9 | failed

// D198 (§16.2b.5, §16.2b.11): `fills param N` — the callee writes the
// record without reading it first. The parameter leaves the list (With
// passes `T.zeroed()`) and the record joins what the operation presents,
// under the status rule of §16.2b.4: nothing returned, the record; a status
// with no `ok`, uninterpreted, `(status, T)`; a status under `ok`,
// `Result[T, E]`.
use c_import("#define SHAPE_OK 0\ntypedef struct { int w; int h; } Size;\nstatic inline void default_size(Size *out) { out->w = 3; out->h = 4; }\nstatic inline int square(int n, Size *out) { out->w = n; out->h = n; return 0; }\nstatic inline int checked_square(int n, Size *out) { if (n < 0) return 1; out->w = n; out->h = n; return SHAPE_OK; }\n")

c facade shapes:
    fn default_size
        fills param out
    fn square
        fills param out
    fn checked_square
        ok SHAPE_OK
        fills param out

fn main:
    let a = default_size()
    let (status, b) = square(7)
    let c = checked_square(9).unwrap()
    let refused = if checked_square(-1).is_err(): "failed" else: "accepted"
    print(f"{a.w} {a.h} | {status} {b.w} {b.h} | {c.w} {c.h} | {refused}")
