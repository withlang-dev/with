//! check-only
// D121 step 6 (spec §16.2b.8): `text return, owned, freed by F` where F is
// an imported global holding a function pointer (libxml2's `xmlFreeFunc
// xmlFree`, the spec's own example), not a function. The rendering
// releases the text through the pointer the global holds at the call; a
// NULL there is the library breaking its contract (D134). `nullable param
// N` on a `const char *` presents `Option[&str]`, NULL for None; and a
// camel-case C name on a struct tag written `_zdoc` shortens as a
// snake-case one does: `zdocGetTitle` is `get_title`.
use c_import("typedef unsigned char xchar;\ntypedef struct _zdoc zdoc;\ntypedef void (*zfreefn)(void *);\nextern zfreefn zfree;\nzdoc *zdocRead(const char *path, const char *encoding);\nvoid zdocFree(zdoc *d);\nxchar *zdocGetTitle(const zdoc *d);\n")

c facade z:
    text utf8
    resource Doc wraps *mut _zdoc
        from zdocRead
        drop zdocFree
    fn zdocRead
        nullable param 1
    fn zdocGetTitle
        lend
        text return, owned, freed by zfree

fn main:
    let Some(d) = Doc.read("a.xml", None) else:
        return 1
    let title: Option[str] = d.get_title()
    if let Some(t) = title: print(t)
