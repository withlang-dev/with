//! expect-error: 'StringBuilder' requires an explicit import (§18.1); add: use std.string.StringBuilder
// #1955 (§18.1, §18.2): a module's imports are its own. issue1955.uses_string_builder
// writes `use std.string.StringBuilder`; importing that module does not make
// the gated std name visible here, in any body-check order.

use issue1955.uses_string_builder

fn main:
    print(joined())
    var sb = StringBuilder.new()
    sb.push_str("c")
    print(sb.to_str())
