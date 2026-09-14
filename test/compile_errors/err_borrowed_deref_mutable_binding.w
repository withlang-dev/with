//! expect-error: cannot take ownership of a non-Copy value through a borrow

fn observe(source: &str):
    var observed = *source
    print(observed)

fn main: observe("alpha")
