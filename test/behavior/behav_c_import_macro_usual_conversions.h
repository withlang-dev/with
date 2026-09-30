/* #1911: glibc's <limits.h> spells ULLONG_MAX `(LLONG_MAX * 2ULL + 1)`, an
 * operator over a named signed constant and an unsigned literal. c_import
 * translates a system header's macro body itself, as it translates every
 * function-like macro's (an object macro here is folded by clang), so the
 * translator applies C's usual arithmetic conversions (C11 6.3.1.8). */
#define W1911_LLONG_MAX __LONG_LONG_MAX__
#define W1911_UINT_MAX (__INT_MAX__ * 2U + 1U)
#define W1911_ULLONG_MAX() (W1911_LLONG_MAX * 2ULL + 1)
#define W1911_UNSIGNED_WINS() ((W1911_LLONG_MAX * 2ULL + 1) - W1911_LLONG_MAX)
#define W1911_SIGNED_WIDER() (W1911_LLONG_MAX - W1911_UINT_MAX)
#define W1911_BITWISE() (W1911_LLONG_MAX | 0x8000000000000000ULL)
#define W1911_COMPARED() ((W1911_LLONG_MAX * 2ULL + 1) > W1911_LLONG_MAX)
