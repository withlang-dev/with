//! expect-stdout: content: héllo 6
//! expect-stdout: raw: 5 104 111
//! expect-stdout: none: true
//! expect-stdout: ok

// D134 (§16.2b.8): a facade declares `text utf8` once, and every `text
// return, owned, freed by F` in it presents as `Option[str]`: the bytes are
// validated at the boundary and copied into a `str`, F runs on the C
// pointer, NULL is None. An item overrides with `text return bytes` and
// keeps `Option[List[u8]]` (unknown encoding is bytes, §16.2b.2).
use c_import("#include <stdlib.h>
typedef unsigned char xchar;
typedef struct zdoc { int n; } zdoc;
static inline zdoc *zdoc_new(int n) { zdoc *d = (zdoc *)malloc(sizeof(zdoc)); d->n = n; return d; }
static inline void zdoc_free(zdoc *d) { free(d); }
static inline xchar *zdoc_content(const zdoc *d) { if (d->n == 0) return 0; xchar *s = (xchar *)malloc(7); s[0] = 'h'; s[1] = 0xC3; s[2] = 0xA9; s[3] = 'l'; s[4] = 'l'; s[5] = 'o'; s[6] = 0; return s; }
static inline xchar *zdoc_raw(const zdoc *d) { xchar *s = (xchar *)malloc(6); s[0] = 'h'; s[1] = 'e'; s[2] = 'l'; s[3] = 'l'; s[4] = 'o'; s[5] = 0; return s; }
static inline void zfree(void *p) { free(p); }
")

c facade z:
    text utf8
    resource Document wraps *mut zdoc
        from zdoc_new
        drop zdoc_free
    fn zdoc_content
        lend
        text return, owned, freed by zfree
    fn zdoc_raw
        lend
        text return, owned, freed by zfree
        text return bytes

fn main:
    let Some(d) = Document.new(3) else:
        return 1
    let Some(content) = d.content() else:
        return 2
    print(f"content: {content} {content.len()}")
    let Some(raw) = d.raw() else:
        return 3
    print(f"raw: {raw.len()} {raw[0]} {raw[4]}")
    let Some(empty) = Document.new(0) else:
        return 4
    print(f"none: {empty.content().is_none()}")
    print("ok")
