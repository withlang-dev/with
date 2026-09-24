//! expect-stdout: filled: 5 of 8
//! expect-stdout: bytes: 104 101 108 108 111
//! expect-stdout: too small: Failed(1)
//! expect-stdout: dest still: 8
//! expect-stdout: renamed: 3
//! expect-stdout: void: 4
//! expect-stdout: ok

// D64 (spec §16.2b.8): `buffer param dst capacity param dstLen inout`
// renders the pointer and the pointer-to-length as one `[]mut u8` whose
// length is the capacity C receives; the length C writes back is
// bounds-checked against that capacity and presented as the operation's
// `usize` result, on success only — `ok FILL_OK` is the status contract,
// so the operation returns `Result[usize, FillError]`. The caller's slice
// is not modified (Eric: "no strange mutation of the caller's slice
// metadata"): `dest` is 8 bytes before and after a fill of 5. A `rename`
// presents the same bridge under another name, and an operation returning
// nothing always succeeded, so its result is a plain `usize`.

use c_import("#define FILL_OK 0\n#define FILL_TOO_SMALL 1\nstatic inline int fill(unsigned char *dst, unsigned long *dstLen, const unsigned char *src, unsigned long srcLen) { if (srcLen > *dstLen) return FILL_TOO_SMALL; unsigned long i = 0; while (i < srcLen) { dst[i] = src[i]; i++; } *dstLen = srcLen; return FILL_OK; }\nstatic inline int fill3(unsigned char *dst, unsigned long *dstLen) { if (*dstLen < 3) return FILL_TOO_SMALL; dst[0] = 1; dst[1] = 2; dst[2] = 3; *dstLen = 3; return FILL_OK; }\nstatic inline void fill_void(char *dst, unsigned int *dstLen) { unsigned int n = 4; if (*dstLen < 4) n = *dstLen; unsigned int i = 0; while (i < n) { dst[i] = 'x'; i++; } *dstLen = n; }\n")

c facade fills:
    fn fill
        buffer param dst capacity param dstLen inout
        buffer param src len param srcLen
        ok FILL_OK
    fn fill3
        buffer param dst capacity param dstLen inout
        ok FILL_OK
        rename fill_three
    fn fill_void
        buffer param dst capacity param dstLen inout

fn main:
    var dest: [u8; 8] = [0 as u8; 8]
    let hello: [u8; 5] = [104, 101, 108, 108, 111]
    let n = fill(dest, hello[..]).unwrap()
    print(f"filled: {n} of {dest.len()}")
    print(f"bytes: {dest[0]} {dest[1]} {dest[2]} {dest[3]} {dest[4]}")
    var small: [u8; 2] = [0 as u8; 2]
    match fill(small, hello[..]):
        Err(e) => print(f"too small: {e}")
        Ok(m) => print(f"unexpected: {m}")
    print(f"dest still: {dest.len()}")
    var three: [u8; 4] = [0 as u8; 4]
    print(f"renamed: {fill_three(three).unwrap()}")
    var xs: [u8; 9] = [0 as u8; 9]
    print(f"void: {fill_void(xs)}")
    print("ok")
