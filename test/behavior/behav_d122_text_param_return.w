//! expect-stdout: 5 <a/>x
//! expect-stdout: content: 5 104 111
//! expect-stdout: none: true
//! expect-stdout: ok

// D122 (spec §16.2b.8): `text param P` states that a character-pointer
// parameter of any C character type (libxml2's `const xmlChar *`, an
// unsigned char) is input text C reads to its NUL and does not keep, so it
// accepts a `str` as a `const char *` does. `text return, owned, freed by
// F` states that the returned character pointer is new text the caller
// owns: the rendering copies its bytes out and calls F on the pointer
// (NULL is None). Unknown encoding is bytes (§16.2b.2), so the caller
// receives `Option[List[u8]]` until a return is proved or declared UTF-8.
use c_import("#include <stdlib.h>
typedef unsigned char xchar;
typedef struct zdoc { int n; char first[8]; } zdoc;
static inline zdoc *zdoc_read(const xchar *text) { zdoc *d = (zdoc *)malloc(sizeof(zdoc)); int n = 0; while (text[n]) n++; d->n = n; int i = 0; while (i < 7 && i < n) { d->first[i] = (char)text[i]; i++; } d->first[i] = 0; return d; }
static inline void zdoc_free(zdoc *d) { free(d); }
static inline int zdoc_len(const zdoc *d) { return d->n; }
static inline const char *zdoc_first(const zdoc *d) { return d->first; }
static inline xchar *zdoc_content(const zdoc *d) { if (d->n == 0) return 0; xchar *s = (xchar *)malloc(6); s[0] = 'h'; s[1] = 'e'; s[2] = 'l'; s[3] = 'l'; s[4] = 'o'; s[5] = 0; return s; }
static inline void zfree(void *p) { free(p); }
")

c facade z:
    resource Document wraps *mut zdoc
        from zdoc_read
        drop zdoc_free
    fn zdoc_read
        text param 0
    fn zdoc_len
        lend
    fn zdoc_first
        lend
        returns borrow CStr from param 0
    fn zdoc_content
        lend
        text return, owned, freed by zfree

fn main:
    let d = Document.read("<a/>x").unwrap()
    print(f"{d.len()} {d.first().unwrap().to_str_lossy()}")
    let c = d.content().unwrap()
    print(f"content: {c.len()} {c[0]} {c[4]}")
    let e = Document.read("").unwrap()
    print(f"none: {e.content().is_none()}")
    print("ok")
