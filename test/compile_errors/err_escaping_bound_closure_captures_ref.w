//! expect-check-fail: escaping closure cannot capture ephemeral references

fn bad:
    let x = 42
    let r = &x
    let f = () => *r
    let _ = f()
