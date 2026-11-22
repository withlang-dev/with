//! expect-stdout: 294 5
//! expect-stdout: 294 195 0
//! expect-stdout: 394
//! expect-stdout: 60
//! expect-stdout: wrote 0 read 3: 97 98 99

// #3130 (§16.2b.8): a `str` is accepted where a contract renders an input
// buffer: its bytes and their length are supplied, as `s as []u8` supplies
// them. A free operation over `const char *` and over `const void *`, a
// resource's method, a `&str`, a literal, an empty string and a temporary.

use c_import("#define NOTE_OK 0\nvoid *malloc(unsigned long size);\nvoid free(void *p);\nstatic inline int sum(const unsigned char *src, unsigned long n) { int t = 0; unsigned long i = 0; while (i < n) { t += src[i]; i++; } return t; }\nstatic inline int sumv(const void *src, unsigned long n) { const unsigned char *p = (const unsigned char *)src; int t = 0; unsigned long i = 0; while (i < n) { t += p[i]; i++; } return t; }\nunsigned long strnlen(const char *s, unsigned long maxlen);\ntypedef struct note { unsigned char buf[16]; unsigned long len; } note;\nstatic inline note *note_new(void) { note *n = (note *)malloc(sizeof(note)); n->len = 0; return n; }\nstatic inline void note_free(note *n) { free(n); }\nstatic inline int note_write(note *n, const unsigned char *p, unsigned long len) { unsigned long i = 0; if (len > 16) return 1; while (i < len) { n->buf[i] = p[i]; i++; } n->len = len; return NOTE_OK; }\nstatic inline int note_read(note *n, unsigned char *dst, unsigned long *dstLen) { unsigned long i = 0; if (n->len > *dstLen) return 1; while (i < n->len) { dst[i] = n->buf[i]; i++; } *dstLen = n->len; return NOTE_OK; }\n")

c contract sums:
    resource Note wraps *mut note
        from note_new
        drop note_free
    fn sum
        buffer param src len param n
    fn sumv
        buffer param src len param n
    fn strnlen
        buffer param s len param maxlen
    fn note_write
        lend
        buffer param p len param len
    fn note_read
        lend
        buffer param dst capacity param dstLen inout
        ok NOTE_OK

fn through_view(s: &str) -> i32: sum(s)

fn main:
    let body = "abc"
    print(f"{sum(body)} {strnlen("hello")}")
    print(f"{sumv(body)} {through_view("ab")} {strnlen("")}")
    print(sum(body ++ "d"))
    let bytes: List[u8] = [10, 20, 30]
    print(sum(bytes))
    let n = Note.new().unwrap()
    let wrote = n.write(body)
    var out: [u8; 8] = [0 as u8; 8]
    let got = n.read(out).unwrap()
    print(f"wrote {wrote} read {got}: {out[0]} {out[1]} {out[2]}")
