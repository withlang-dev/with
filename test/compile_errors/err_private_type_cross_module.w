//! expect-check-fail: symbol 'PrivateType' is private to module

use visibility.private_surface

fn main:
    let _x: PrivateType = PrivateType { value: 1 }
