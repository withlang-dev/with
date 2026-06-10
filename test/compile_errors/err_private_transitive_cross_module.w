//! expect-check-fail: symbol 'private_fn' is private to module

use visibility.transitive_mid

fn main:
    let _x = private_fn()
