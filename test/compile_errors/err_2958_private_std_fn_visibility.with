//! expect-check-fail: symbol 'tommy_ilog2_u32' is private to its package
//! expect-check-fail: symbol 'http_parse_url' is private to its package

// #2958 (§18.3, D100): calling a non-`pub` std function — whether displaced
// across modules (`tommy_ilog2_u32`) or in an unimported std module
// (`http_parse_url`) — reports the §18.3 package-privacy error naming the
// declaring module rather than "undefined variable".

use std.engines.tommyds.tommyhashlin
use std.http.https_get

fn main:
    let _a = tommy_ilog2_u32(4u32)
    let _b = http_parse_url("https://example.com")
