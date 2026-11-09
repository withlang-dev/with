//! expect-stdout: 1 1

// #3187: a script's top-level binding is injected into its helpers (D184);
// a helper's call of a generic method then checked that method's body in
// an environment that had the injected binding but not its script mark,
// so std's own `let i` in enumerate's `next` was refused as shadowing the
// program's `var i`. Another module's local never shadows a script binding.
fn count(xs: &List[str]) -> i32:
    var n = 0
    for (k, x) in xs.enumerate():
        if x.len() > 0: n = n + k as i32
    n

var i = 1
print(f"{count(&["a", "b"])} {i}")
