//! expect-stdout: sum: 10
//! expect-stdout: absent: true
//! expect-stdout: ok

// D65 phase 5 (#2043): a facade call in a pipeline stage is the call Sema
// resolved, as it is in call position. `arr[..] |> sum_bytes()` calls the
// D64 bridge the C name is presented as (the slice is the pointer and its
// length, §16.2b.8); `name |> getenv()` is the presented text view, the
// `Option[CStr]` of C's pointer (§16.2b.8). MirLower lowered both by the
// spelling — the raw two-parameter C declaration with one argument, and the
// pointer as the Option — because its facade tables were read only in
// lower_call; it now reads Sema's resolution and value conversion for
// every call.

use c_import("static inline int sum_bytes(const unsigned char *p, unsigned long n) { int s = 0; unsigned long i = 0; while (i < n) { s += p[i]; i++; } return s; }\nchar *getenv(const char *name);\n")

c facade sums:
    fn sum_bytes
        buffer param p len param n

fn main:
    let arr: [u8; 4] = [1, 2, 3, 4]
    print(f"sum: {arr[..] |> sum_bytes()}")
    let v = "WITH_DEFINITELY_ABSENT_VAR_XYZZY_2043" |> getenv()
    print(f"absent: {v.is_none()}")
    print("ok")
