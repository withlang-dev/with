//! expect-check-fail: resource 'Tokens': 'borrows' names param 0: *const i8 text of 'tk_new', which receives no modeled resource; a resource depends on the parent resources its producer receives, and With does not invent an origin for anything else (§16.2b.6, §16.2b.7)

// D51 stage 6 (ruling §27, §31; spec §16.2b.6-7): a dependency's parent is a
// modeled resource the producer receives; a borrowed foreign pointer has a
// real modeled origin, and a `const char *` input is none. The diagnostic
// prints the resolved C parameter (§57).

use c_import("typedef struct tk tk;
tk* tk_new(const char* text);
void tk_free(tk* t);
")

c facade dep:
    resource Tokens wraps *mut tk
        from tk_new
        drop tk_free
        borrows param 0

fn main:
    print("x")
