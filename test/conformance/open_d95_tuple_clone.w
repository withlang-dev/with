//! expect-stdout: true
// D95 (§11.8): a tuple implements Clone when its elements do. #2945
let t = (1, "a")
let u = t.clone()
print(t == u)
