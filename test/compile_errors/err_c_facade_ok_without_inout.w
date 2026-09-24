//! expect-check-fail: pairs no 'capacity … inout' buffer, so there is no value to present on success

// D64 §16.2b.8: `ok` on an fn item is the status contract of a copied-back
// length; without one there is nothing it projects.
use c_import("#define SUM_OK 0\nstatic inline int sum_bytes(const unsigned char *p, unsigned long n) { if (n > 0) return p[0]; return 0; }\n")

c facade sums:
    fn sum_bytes
        buffer param p len param n
        ok SUM_OK

fn main:
    print("unreachable")
