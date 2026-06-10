//! expect-check-fail: symbol 'PRIVATE_CONST' is private to module

use visibility.private_surface

fn main:
    let _x = PRIVATE_CONST
