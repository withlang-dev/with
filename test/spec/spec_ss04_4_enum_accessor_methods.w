// Spec test: Section 4.4 - Enum Accessor Methods.

enum AccessToken { TInt(i64) | TStr(str) | TBool(bool) | TPair(i32, i32) | TNull }

fn test_enum_is_accessors:
    let t = AccessToken.TInt(42)
    assert(t.is_tint())
    assert(not t.is_tstr())
    assert(not t.is_tnull())

fn test_enum_as_accessors_return_option:
    let s = AccessToken.TStr("hello")
    match s.as_tstr():
        Some(text) => assert(text == "hello")
        None => assert(false)

    let n = AccessToken.TStr("hello")
    let missing = n.as_tint()
    assert(missing.is_none())

fn test_enum_as_accessor_with_double_question:
    let t = AccessToken.TInt(42)
    let n = t.as_tint() ?? 0
    assert(n == 42)

fn test_enum_as_accessor_multi_field_tuple:
    let pair = AccessToken.TPair(3, 4)
    match pair.as_tpair():
        Some((left, right)) =>
            assert(left == 3)
            assert(right == 4)
        None => assert(false)

fn test_enum_as_ref_accessor_borrows_payload:
    let t = AccessToken.TInt(42)
    match t.as_tint_ref():
        Some(n) => assert(*n == 42)
        None => assert(false)
    assert(t.is_tint())

enum AccessColor { Red | Green | Blue }

fn test_enum_unit_variants_only_generate_is_accessors:
    let c = AccessColor.Red
    assert(c.is_red())
    assert(not c.is_green())

enum AccessResult2 { Success(i32) | Failure(str) }

fn test_enum_accessor_works_with_variant_shorthand:
    let ok: AccessResult2 = .Success(10)
    assert((ok.as_success() ?? 0) == 10)

    let err_missing = AccessResult2.Success(10).as_failure()
    assert(err_missing.is_none())
