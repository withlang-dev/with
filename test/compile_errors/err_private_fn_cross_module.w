//! expect-check-fail: symbol 'private_fn' is private to module

use visibility.private_surface

fn main:
    let _x = private_fn()
