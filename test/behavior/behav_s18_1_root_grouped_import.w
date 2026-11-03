//! expect-stdout: ok
// §18.1: a grouped import at the package root. #2948
use std.{fs, process}
let _ = process.args().len()
print("ok")
