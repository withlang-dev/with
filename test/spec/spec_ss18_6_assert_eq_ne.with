// Spec test: Section 18.6 — assert_eq / assert_ne (formerly 25.49)
// Generic prelude assertions over Eq + Debug that show both values on failure.

fn test_assert_eq_int:
    assert_eq(2 + 2, 4)

fn test_assert_ne_int:
    assert_ne(2 + 2, 5)

fn test_assert_eq_str:
    assert_eq("ab" ++ "c", "abc")

fn test_assert_ne_str:
    assert_ne("abc", "abd")

fn test_assert_eq_bool:
    assert_eq(1 < 2, true)
    assert_ne(1 > 2, true)
