//! expect-error: shadowing is not allowed for 'sin': it names a field of the receiver `Wave` and the function `sin` (§9.5)

// §9.5 (#1930): a compiler intrinsic called by its bare name (`sin`,
// `src`, `sizeof[T]()`) is a module-level function to the programmer, as a
// prelude function is, so a field of the same name makes the bare name a
// shadowing error; the field does not take precedence.

type Wave {
    sin: f64,
}

impl Wave:
    fn level -> f64: sin * 2.0

fn main:
    let w = Wave { sin: 0.5 }
    print(f"{w.level()}")
