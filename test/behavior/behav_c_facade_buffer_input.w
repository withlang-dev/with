//! expect-stdout: sum: 10
//! expect-stdout: empty: 0
//! expect-stdout: vec: 6
//! expect-stdout: zeros: 2
//! expect-stdout: ok

// D64 (spec §16.2b.8): `buffer param p len param n` renders the pointer and
// the integer that carries its byte length as one `[]u8`; the bridge
// supplies both from the slice — a null pointer and 0 for an empty one.
// The pairing is stated; the C types (`const unsigned char *` + `unsigned
// long`, `const void *` + `unsigned int`) prove nothing on their own. The
// operation is presented under its C name: a call to `sum_bytes` in a
// module where the facade is visible is the presented call, and takes the
// slice, no pointer and no length.

use c_import("static inline int sum_bytes(const unsigned char *p, unsigned long n) { int s = 0; unsigned long i = 0; while (i < n) { s += p[i]; i++; } return s; }\nstatic inline int count_zero(const void *p, unsigned int n) { const unsigned char *b = (const unsigned char *)p; int z = 0; unsigned int i = 0; while (i < n) { if (b[i] == 0) z++; i++; } return z; }\n")

c facade sums:
    fn sum_bytes
        buffer param p len param n
    fn count_zero
        buffer param p len param n

fn main:
    let arr: [u8; 4] = [1, 2, 3, 4]
    print(f"sum: {sum_bytes(arr[..])}")
    let empty: [u8; 0] = []
    print(f"empty: {sum_bytes(empty[..])}")
    var v: Vec[u8] = Vec.new()
    v.push(1)
    v.push(2)
    v.push(3)
    print(f"vec: {sum_bytes(v)}")
    let holes: [u8; 5] = [0, 7, 0, 7, 7]
    print(f"zeros: {count_zero(holes[..])}")
    print("ok")
