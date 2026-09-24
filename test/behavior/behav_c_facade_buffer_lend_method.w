//! expect-stdout: wrote: 3
//! expect-stdout: read: 3
//! expect-stdout: bytes: 10 20 30
//! expect-stdout: read small: Failed(1)
//! expect-stdout: ok

// D64 (spec §16.2b.8) on a resource's lend methods: `buffer param p len
// param n` on `note_write(note *, const unsigned char *, unsigned long)`
// presents `n.write(data)` over a `[]u8`; `buffer param dst capacity param
// dstLen inout` with `ok NOTE_OK` on `note_read(note *, unsigned char *,
// unsigned long *)` presents `n.read(buf) -> Result[usize, ReadError]` —
// the same bridge as a free operation, with the receiver in front, and
// the `<Fn>Error` named after the presented method.

use c_import("#define NOTE_OK 0\n#define NOTE_TOO_SMALL 1\nvoid *malloc(unsigned long size);\nvoid free(void *p);\ntypedef struct note { unsigned char buf[16]; unsigned long len; } note;\nstatic inline note *note_new(void) { note *n = (note *)malloc(sizeof(note)); n->len = 0; return n; }\nstatic inline void note_free(note *n) { free(n); }\nstatic inline int note_write(note *n, const unsigned char *p, unsigned long len) { unsigned long i = 0; if (len > 16) return NOTE_TOO_SMALL; while (i < len) { n->buf[i] = p[i]; i++; } n->len = len; return NOTE_OK; }\nstatic inline int note_read(note *n, unsigned char *dst, unsigned long *dstLen) { unsigned long i = 0; if (n->len > *dstLen) return NOTE_TOO_SMALL; while (i < n->len) { dst[i] = n->buf[i]; i++; } *dstLen = n->len; return NOTE_OK; }\n")

c facade notes:
    resource Note wraps *mut note
        from note_new
        drop note_free
    fn note_write
        lend
        buffer param p len param len
    fn note_read
        lend
        buffer param dst capacity param dstLen inout
        ok NOTE_OK

fn main:
    let n = Note.new().unwrap()
    let data: [u8; 3] = [10, 20, 30]
    print(f"wrote: {if n.write(data[..]) == NOTE_OK: 3 else: -1}")
    var out: [u8; 8] = [0 as u8; 8]
    let got = n.read(out).unwrap()
    print(f"read: {got}")
    print(f"bytes: {out[0]} {out[1]} {out[2]}")
    var small: [u8; 2] = [0 as u8; 2]
    match n.read(small):
        Err(e) => print(f"read small: {e}")
        Ok(m) => print(f"unexpected: {m}")
    print("ok")
