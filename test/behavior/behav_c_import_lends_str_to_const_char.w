//! expect-stdout: ok

// §16.3c, D47: evidence governs what With receives from C; a `str` lent to a
// c_imported `const char *` parameter for the call needs none. `remove` and
// `rename` are not in the curated overlay, and both are callable with a
// literal (passed directly) and with a runtime `str` (lent from storage that
// stays readable), with no `unsafe`. This replaces
// err_c_import_const_char_requires_overlay_evidence, which asserted #379's
// rule that such a call is the raw surface.

use c_import("int remove(const char *path);\nint rename(const char *from, const char *to);\nunsigned long strlen(const char *s);\n")

fn main:
    assert(remove("/no/such/dir/with-lend-literal") != 0)
    let missing = f"/no/such/dir/with-lend-{7}"
    assert(remove(missing) != 0)
    assert(rename(missing, "/no/such/dir/other") != 0)

    // Every size class of the lending storage, reused across iterations, up
    // past the size that gets a mapping of its own.
    var small = ""
    for n in 0..130:
        assert(strlen(small) == n as usize)
        small = small ++ "x"
    var big = "with"
    while big.len() < 300000:
        assert(strlen(big) == big.len() as usize)
        big = big ++ big
    assert(strlen("") == 0usize)
    print("ok")
