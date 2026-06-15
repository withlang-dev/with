//! check-only

use lib.generic_private_body

fn test_generic_method_body_uses_defining_module_visibility:
    let wrapped = GenericPrivateWrapper.make(42)
    assert(wrapped.value == 42)
    assert(wrapped.private_value() == 11)
