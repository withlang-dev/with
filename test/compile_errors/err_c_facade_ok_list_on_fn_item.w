//! expect-check-fail: 'ok' lists several success statuses, which a producer's 'ok' on its resource may

// Spec §16.2b.4 (ruling Amendment 1, #1432): "A producer's `ok` may list
// several compile-time constants." An fn item's `ok` — the status contract
// a copied-back length is presented under (D64) — names one; a list there
// is refused, never read as its first constant.
use c_import("#define GET_OK 0\n#define GET_SHORT 1\nstatic inline int get_bytes(unsigned char *p, unsigned long *n) { if (*n > 0) p[0] = 7; *n = 1; return GET_OK; }\n")

c facade gets:
    fn get_bytes
        buffer param p capacity param n inout
        ok GET_OK, GET_SHORT

fn main:
    print("unreachable")
