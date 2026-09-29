//! expect-check-fail: `writes CONFIG.limit` names part of the global `CONFIG`: a `writes` clause names whole globals

// §21.1 rule 1 (Eric 2026-09-29): a `writes` clause names whole globals in
// v1; a field path is refused, with `writes CONFIG` as the fix.
type Config { limit: i32 }
var CONFIG = Config { limit: 1 }

fn raise() writes CONFIG.limit: CONFIG.limit = CONFIG.limit + 1

fn main:
    raise()
    print(CONFIG.limit)
