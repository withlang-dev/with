//! expect-check-fail: resource 'Tokens': 'borrows' names param 0: *const c_char text of 'tk_new', which receives no modeled resource; a resource depends on the parent resources its producer receives, and With does not invent an origin for anything else (§16.2b.6, §16.2b.7)
//! expect-check-fail: = help: after 'borrows' name the producer's parameter that receives a declared resource, or declare that resource first

// D51 stage 6 (ruling §27, §31; spec §16.2b.6-7): a dependency's parent is a
// modeled resource the producer receives; a borrowed foreign pointer has a
// real modeled origin, and a `const char *` input is none. The diagnostic
// prints the resolved C parameter (§57).

use c_import("typedef struct tk tk;
tk* tk_new(const char* text);
void tk_free(tk* t);
")

c contract dep:
    resource Tokens wraps *mut tk
        from tk_new
        drop tk_free
        borrows param 0

fn main:
    print("x")
