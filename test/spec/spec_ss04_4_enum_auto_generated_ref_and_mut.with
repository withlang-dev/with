// Spec test: Section 4.4 - Enum Auto-Generated _ref and _mut.

enum RefMutValue { Str(str) | Num(f64) | Pair(i32, i32) | Null }

fn test_enum_as_variant_ref_returns_option_ref:
    let v = RefMutValue.Str("hello")
    match v.as_str_ref():
        Some(text) => assert(*text == "hello")
        None => assert(false)
    assert(v.as_num_ref().is_none())

fn test_enum_as_variant_mut_updates_payload:
    let v = RefMutValue.Num(42.0)
    match v.as_num_mut():
        Some(n) => *n = 99.0
        None => assert(false)

    match v.as_num_ref():
        Some(n) => assert(*n == 99.0)
        None => assert(false)

fn test_enum_as_variant_mut_returns_none_for_other_variant:
    let v = RefMutValue.Str("hello")
    assert(v.as_num_mut().is_none())
    match v.as_str_ref():
        Some(text) => assert(*text == "hello")
        None => assert(false)

fn test_enum_as_variant_mut_multi_field_tuple:
    let v = RefMutValue.Pair(3, 4)
    match v.as_pair_mut():
        Some((left, right)) =>
            *left = 30
            *right = 40
        None => assert(false)

    match v.as_pair_ref():
        Some((left, right)) =>
            assert(*left == 30)
            assert(*right == 40)
        None => assert(false)
