// #1955: this module's own `use` must not reach its importers.
use std.string.StringBuilder

pub fn joined() -> str:
    var sb = StringBuilder.new()
    sb.push_str("a")
    sb.push_str("b")
    sb.to_str()
