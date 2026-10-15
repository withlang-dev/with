//! expect-exit: 134
//! expect-stderr: zdoc_content: the facade declares its text UTF-8, but the text returned is not UTF-8 at byte 1 (§16.2b.8)

// D134 (§16.2b.8): a declaration is a claim about the library. A text return
// under `text utf8` that is not UTF-8 is a contract failure that names the
// C function; nothing is repaired, and the user's data is never rewritten.
use c_import("#include <stdlib.h>
typedef unsigned char xchar;
typedef struct zdoc { int n; } zdoc;
static inline zdoc *zdoc_new(int n) { zdoc *d = (zdoc *)malloc(sizeof(zdoc)); d->n = n; return d; }
static inline void zdoc_free(zdoc *d) { free(d); }
static inline xchar *zdoc_content(const zdoc *d) { xchar *s = (xchar *)malloc(4); s[0] = 'h'; s[1] = 0xFF; s[2] = 'i'; s[3] = 0; return s; }
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

fn main:
    let Some(d) = Document.new(1) else:
        return 1
    let content = d.content()
    print(f"{content.is_some()}")
