//! expect-stdout: [2]

// #2978: a comprehension over a map global in a script (D184) binds `v` as
// a `&V` view (D44) and reads it as a value in the element expression; the
// script-init lowering once multiplied the pointer.
use std.collections
var m: HashMap[str, i32] = HashMap.new()
m.insert("alpha".to_owned(), 1)
let doubled = [v * 2 for (k, v) in m]
print(f"{doubled:?}")
