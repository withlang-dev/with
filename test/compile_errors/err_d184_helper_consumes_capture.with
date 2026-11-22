//! expect-error: a helper does not own the script binding `xs`

// D184 (§29.15, Law 5): a helper that names a script binding captures it,
// observing or mutating it, never consuming it.

let xs: List[i32] = [1, 2]
fn grab() -> List[i32]: move xs
let got = grab()
print(xs.len())
