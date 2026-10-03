//! expect-error: bare 'sin' names both a field of the receiver `Wave` and the function `sin` (§9.5)

// §9.5 (#1930): a bare name that resolves to a receiver field and to any
// other name in scope is an error at that use. A compiler intrinsic called
// by its bare name is such a name; the field does not take precedence.
// `self.sin` and `builtins.sin(x)` reach each (behav_receiver_field_qualified_forms.w).

type Wave {
    sin: f64,
}

impl Wave:
    fn level(x: f64) -> f64: sin(x) * self.sin

fn main:
    let w = Wave { sin: 0.5 }
    print(f"{w.level(1.0)}")
