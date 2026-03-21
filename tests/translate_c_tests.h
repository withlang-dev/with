// translate_c_tests.h — C header for porting Zig translate-c test cases
// Each section corresponds to test cases from .reference/translate-c/test/cases/

#ifndef TRANSLATE_C_TESTS_H
#define TRANSLATE_C_TESTS_H

#include <stdint.h>
#include <stddef.h>

// ── Macros: literals and expressions ──────────────────────────────

#define TC_INT_CONST 42
#define TC_NEG_CONST (-7)
#define TC_HEX_CONST 0xFF
#define TC_LONG_CONST 100L
#define TC_ULONG_CONST 200UL
#define TC_LLONG_CONST 300LL
#define TC_FLOAT_CONST 3.14f
#define TC_DOUBLE_CONST 2.718
#define TC_CHAR_CONST 'A'
#define TC_STRING_CONST "hello"
#define TC_BOOL_TRUE 1
#define TC_BOOL_FALSE 0

// ── Macros: arithmetic ───────────────────────────────────────────

#define TC_ADD(a, b) ((a) + (b))
#define TC_MUL(a, b) ((a) * (b))
#define TC_NEGATE(x) (-(x))
#define TC_SHIFT_LEFT(x, n) ((x) << (n))
#define TC_SHIFT_RIGHT(x, n) ((x) >> (n))
#define TC_BITAND(a, b) ((a) & (b))
#define TC_BITOR(a, b) ((a) | (b))
#define TC_BITXOR(a, b) ((a) ^ (b))
#define TC_BITNOT(x) (~(x))

// ── Macros: comparisons and logical ops ──────────────────────────

#define TC_EQ(a, b) ((a) == (b))
#define TC_NEQ(a, b) ((a) != (b))
#define TC_LT(a, b) ((a) < (b))
#define TC_GT(a, b) ((a) > (b))
#define TC_AND(a, b) ((a) && (b))
#define TC_OR(a, b) ((a) || (b))
#define TC_NOT(x) (!(x))
#define TC_TERNARY(c, t, f) ((c) ? (t) : (f))

// ── Macros: casts ────────────────────────────────────────────────

#define TC_CAST_TO_INT(x) ((int)(x))
#define TC_CAST_TO_UINT(x) ((unsigned int)(x))
#define TC_CAST_TO_FLOAT(x) ((float)(x))
#define TC_CAST_TO_LONG(x) ((long)(x))

// ── Macros: sizeof and offsetof ──────────────────────────────────

#define TC_SIZEOF_INT (sizeof(int))
#define TC_SIZEOF_PTR (sizeof(void*))
#define TC_SIZEOF_CHAR (sizeof(char))

// ── Macros: void cast / discard ──────────────────────────────────

#define TC_DISCARD(x) ((void)(x))
#define TC_VOID_ZERO ((void)0)

// ── Macros: define referencing define ────────────────────────────

#define TC_BASE 10
#define TC_DERIVED (TC_BASE + 5)
#define TC_CHAINED (TC_DERIVED * 2)

// ── Macros: __extension__ (glibc pattern) ────────────────────────

#define TC_EXTENSION_INT __extension__ 42
#define TC_EXTENSION_EXPR __extension__ (1 + 2)

// ── Enums ────────────────────────────────────────────────────────

typedef enum {
    TC_ENUM_A = 0,
    TC_ENUM_B = 1,
    TC_ENUM_C = 2,
    TC_ENUM_D = 100,
} tc_enum_t;

typedef enum {
    TC_NEG_ENUM_A = -1,
    TC_NEG_ENUM_B = -100,
    TC_NEG_ENUM_C = 50,
} tc_neg_enum_t;

// anonymous enum
enum { TC_ANON_X = 10, TC_ANON_Y = 20, TC_ANON_Z = 30 };

// ── Simple struct ────────────────────────────────────────────────

typedef struct {
    int x;
    int y;
} tc_point_t;

// ── Nested struct ────────────────────────────────────────────────

typedef struct {
    tc_point_t origin;
    tc_point_t size;
} tc_rect_t;

// ── Struct with various field types ──────────────────────────────

typedef struct {
    int8_t   i8_field;
    uint8_t  u8_field;
    int16_t  i16_field;
    uint16_t u16_field;
    int32_t  i32_field;
    uint32_t u32_field;
    int64_t  i64_field;
    uint64_t u64_field;
    float    f32_field;
    double   f64_field;
} tc_types_t;

// ── Packed struct ────────────────────────────────────────────────

typedef struct __attribute__((packed)) {
    uint8_t  a;
    uint32_t b;
    uint8_t  c;
} tc_packed_t;

// ── Struct with pointer fields ───────────────────────────────────

typedef struct {
    int *data;
    size_t len;
} tc_slice_t;

// ── Forward-declared struct ──────────────────────────────────────

typedef struct tc_forward tc_forward_t;
struct tc_forward {
    int value;
    tc_forward_t *next;
};

// ── Typedef struct (same name pattern) ───────────────────────────

typedef struct tc_node {
    int data;
    struct tc_node *left;
    struct tc_node *right;
} tc_node;

// ── Union ────────────────────────────────────────────────────────

typedef union {
    int32_t  as_int;
    float    as_float;
    uint8_t  as_bytes[4];
} tc_union_t;

// ── Function declarations ────────────────────────────────────────

int tc_add(int a, int b);
int tc_mul(int a, int b);
void tc_swap(int *a, int *b);
int tc_abs(int x);
const char *tc_greeting(void);
size_t tc_strlen_custom(const char *s);

// ── Function pointer typedef ─────────────────────────────────────

typedef int (*tc_binop_fn)(int, int);

// ── Struct with function pointer ─────────────────────────────────

typedef struct {
    tc_binop_fn op;
    int initial;
} tc_reducer_t;

// ── Global variables ─────────────────────────────────────────────

extern int tc_global_counter;
extern const int tc_global_const;

// ── Constants via macros ─────────────────────────────────────────

#define TC_MAX_SIZE 1024
#define TC_PI 3.14159265358979323846
#define TC_VERSION_MAJOR 1
#define TC_VERSION_MINOR 2
#define TC_VERSION_PATCH 3
#define TC_VERSION_STR "1.2.3"

// ── Flexible array member ────────────────────────────────────────

typedef struct {
    uint32_t count;
    int items[];
} tc_flex_array_t;

// ── Struct with [1] trailing array (old-style FAM) ───────────────

typedef struct {
    uint32_t count;
    char data[1];
} tc_old_flex_t;

// ── Offsetof ─────────────────────────────────────────────────────

#define TC_OFFSETOF_X offsetof(tc_point_t, x)
#define TC_OFFSETOF_Y offsetof(tc_point_t, y)

// ── Conditional macros ───────────────────────────────────────────

#define TC_MAX(a, b) ((a) > (b) ? (a) : (b))
#define TC_MIN(a, b) ((a) < (b) ? (a) : (b))
#define TC_CLAMP(x, lo, hi) ((x) < (lo) ? (lo) : ((x) > (hi) ? (hi) : (x)))
#define TC_ABS(x) ((x) < 0 ? -(x) : (x))

// ── Comma operator macro ────────────────────────────────────────

#define TC_COMMA_TEST(x) (0, (x))

// ── Pointer-to-bool and bool-to-int patterns ─────────────────────

int tc_ptr_is_null(const void *p);
int tc_ptr_is_nonnull(const void *p);
int tc_bool_to_int(int cond);
int tc_sign(int v);

#endif // TRANSLATE_C_TESTS_H
