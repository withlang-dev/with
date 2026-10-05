//! expect-stdout: empty: true
//! expect-stdout: zero: true
//! expect-stdout: nonzero: Failed(4)
//! expect-stdout: ok

// D92 (ruling Amendment 3, §16.2b.4): `ok` on a status-returning function
// that no resource hosts. Before the amendment `ok` on an fn item was only
// the status contract of a copied-back length (D64) and this facade was
// refused ("no value to present on success"); the status is now the whole
// return, and the presented function is `Result[Unit, SumBytesError]`.
use c_import("#define SUM_OK 0\nstatic inline int sum_bytes(const unsigned char *p, unsigned long n) { if (n > 0) return p[0]; return 0; }\n")

c facade sums:
    fn sum_bytes
        buffer param p len param n
        ok SUM_OK

fn main:
    let none: Vec[u8] = Vec.new()
    print(f"empty: {sum_bytes(none).is_ok()}")
    let zero: [2]u8 = [0, 9]
    print(f"zero: {sum_bytes(zero).is_ok()}")
    let four: [1]u8 = [4]
    match sum_bytes(four):
        Err(e) => print(f"nonzero: {e:?}")
        Ok(_) => print("unexpected")
    print("ok")
