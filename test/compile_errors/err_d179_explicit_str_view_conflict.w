//! expect-check-fail: cannot mutate `parts` while `v` is a live view into it

// D179 (§3.8): a written `&` asks for the view of the `str`, and a view
// still conflicts with a write of its root.
fn main:
    var parts: List[str] = ["alpha"]
    let v = &parts[0]
    parts.push("beta")
    print(f"{v}")
