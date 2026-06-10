use visibility.public_surface

fn main:
    let value = make_public(5)
    assert(public_value(value) == 5)
    assert(PUBLIC_CONST == 7)
    assert(PUBLIC_GLOBAL == 11)
    assert(same_module_private_sum() == 6)

