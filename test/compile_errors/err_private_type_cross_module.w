//! expect-check-fail: symbol 'PrivateType' is private to its package

use visibility.private_surface

fn main:
    let _x: PrivateType = PrivateType { value: 1 }
