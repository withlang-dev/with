//! expect-check-fail: `base:` reads integer text (§15.5); `f64` is not read in a base

// §15.5 (D203): floating-point text is decimal and takes no base.
fn main:
    let f: Option[f64] = "1".parse(base: 16)
