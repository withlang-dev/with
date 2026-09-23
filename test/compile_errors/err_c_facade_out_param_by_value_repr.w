//! expect-check-fail: which is initialized to NULL and inspected after the call; 'Texture' wraps Tex, which has no NULL

// D51 stage 5, ruling §16, spec §16.2b.4/§16.2b.13: out-parameter
// production initializes the slot to NULL and inspects it after the call, so
// it produces a pointer resource. A by-value representation has no NULL to
// inspect: C filling caller storage is the in-place shape (`init`).

use c_import("typedef struct { int id; } Tex;
int tex_load(const char* path, Tex* out);
void tex_unload(Tex t);
")

c facade gfx:
    resource Texture wraps Tex
        from tex_load(out param 1)
        drop tex_unload

fn main:
    print("ok")
