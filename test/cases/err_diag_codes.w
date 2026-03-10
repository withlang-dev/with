//! expect-stdout: ok

// Compile error test: diagnostic error codes
// Tests that Sema error codes are distinct and correct

use Sema

fn test_error_codes_distinct:
    assert(E_UNDECLARED == 1)
    assert(E_TYPE_MISMATCH == 2)
    assert(E_DUPLICATE == 3)
    assert(E_NOT_CALLABLE == 4)
    assert(E_ARG_COUNT == 5)
    assert(E_NOT_MUTABLE == 6)
    assert(E_MOVED == 7)
    assert(E_NO_FIELD == 8)
    assert(E_NO_METHOD == 9)
    assert(E_NOT_INDEXABLE == 10)
    assert(E_BREAK_OUTSIDE == 11)
    assert(E_CONTINUE_OUTSIDE == 12)
    assert(E_RETURN_MISMATCH == 13)
    assert(E_INVALID_CAST == 14)
    assert(E_GENERIC == 15)

fn test_all_codes_nonzero:
    assert(E_UNDECLARED != 0)
    assert(E_TYPE_MISMATCH != 0)
    assert(E_DUPLICATE != 0)
    assert(E_NOT_CALLABLE != 0)
    assert(E_ARG_COUNT != 0)
    assert(E_NOT_MUTABLE != 0)
    assert(E_MOVED != 0)
    assert(E_NO_FIELD != 0)
    assert(E_NO_METHOD != 0)
    assert(E_NOT_INDEXABLE != 0)
    assert(E_BREAK_OUTSIDE != 0)
    assert(E_CONTINUE_OUTSIDE != 0)
    assert(E_RETURN_MISMATCH != 0)
    assert(E_INVALID_CAST != 0)
    assert(E_GENERIC != 0)

fn main:
    test_error_codes_distinct()
    test_all_codes_nonzero()
    println("ok")
