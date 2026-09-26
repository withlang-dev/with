//! expect-check-fail: fn 'tex_width': 'of Texture' assigns it to a resource param 0: i32 w does not receive; it receives no modeled resource (§16.2b.3)

// #1669: an `of` is verified even when the operation's first parameter
// receives no pointer or in-place resource. Accepted silently, an `of`
// naming a by-value token presented nothing, and the facade's declared
// method was "unknown method" at every call site instead of an error here.

use c_import("typedef struct { int id; } Tex;
static inline Tex tex_load(const char* path) { Tex t; t.id = 1; return t; }
static inline void tex_unload(Tex t) { (void)t; }
static inline int tex_width(int w) { return w; }
")

c facade gfx:
    resource Texture wraps Tex
        from tex_load
        drop tex_unload
    fn tex_width
        of Texture
        rename width
        lend

fn main:
    print("x")
