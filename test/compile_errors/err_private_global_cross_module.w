//! expect-check-fail: symbol 'PRIVATE_GLOBAL' is private to module

use visibility.private_surface

fn main:
    let _x = PRIVATE_GLOBAL
