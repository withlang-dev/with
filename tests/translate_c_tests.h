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

static inline int tc_add(int a, int b) { return a + b; }
static inline int tc_mul(int a, int b) { return a * b; }
static inline int tc_abs(int x) { return x < 0 ? -x : x; }

// ── Function pointer typedef ─────────────────────────────────────

typedef int (*tc_binop_fn)(int, int);

// ── Struct with function pointer ─────────────────────────────────

typedef struct {
    tc_binop_fn op;
    int initial;
} tc_reducer_t;

// ── Global variables ─────────────────────────────────────────────

static int tc_global_counter = 0;
static const int tc_global_const = 42;

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

// ── Integer suffix variants (from Zig: l/ll/u/ul/ull suffix tests) ──

#define TC_ZERO_L 0L
#define TC_ZERO_LL 0LL
#define TC_ZERO_U 0U
#define TC_ZERO_UL 0UL
#define TC_ZERO_ULL 0ULL
#define TC_HEX_UPPER 0XFF
#define TC_HEX_MIXED 0xDeAdBeEf
#define TC_LARGE_HEX 0x7FFFFFFFUL

// ── Bitwise NOT on unsigned (from Zig: bitwise_not_on_u-suffixed_0) ──

#define TC_NOT_ZERO_U (~0U)
#define TC_NOT_ZERO_UL (~0UL)

// ── Define referencing define (from Zig: #define_referencing_another_#define) ──

#define TC_THING1 1234
#define TC_THING2 TC_THING1

// ── Shift macros (testing new shift operators) ────────────────────

#define TC_FLAG_READ   (1 << 0)
#define TC_FLAG_WRITE  (1 << 1)
#define TC_FLAG_EXEC   (1 << 2)
#define TC_ALL_FLAGS   (TC_FLAG_READ | TC_FLAG_WRITE | TC_FLAG_EXEC)
#define TC_BYTE_MASK(n) (0xFF << ((n) * 8))
#define TC_EXTRACT_BYTE(val, n) (((val) >> ((n) * 8)) & 0xFF)

// ── Enum auto-increment (from Zig: enums) ────────────────────────

typedef enum {
    TC_AUTO_A = 2,
    TC_AUTO_B = 5,
    TC_AUTO_C,       // should be 6
    TC_AUTO_D,       // should be 7
} tc_auto_enum_t;

// ── Enum with large values (from Zig: big_negative_enum_init_values) ──

typedef enum {
    TC_BIG_A = 0x7FFFFFFF,
    TC_BIG_B = -0x7FFFFFFF,
} tc_big_enum_t;

// ── Struct with array fields ─────────────────────────────────────

typedef struct {
    int values[4];
    char name[32];
    float matrix[3][3];
} tc_array_struct_t;

// ── Self-referential struct (linked list) ────────────────────────

typedef struct tc_list_node {
    int value;
    struct tc_list_node *next;
} tc_list_node_t;

// ── Deeply nested struct ─────────────────────────────────────────

typedef struct {
    struct { int x; int y; } position;
    struct { int w; int h; } size;
} tc_widget_t;

// ── Macro with division/remainder ────────────────────────────────

#define TC_DIV(a, b) ((a) / (b))
#define TC_MOD(a, b) ((a) % (b))

// ── Macro with address-of and dereference ────────────────────────

#define TC_ADDR_OF(x) (&(x))
#define TC_DEREF(p) (*(p))

// ── Multiple typedef names ───────────────────────────────────────

typedef int tc_int_alias;
typedef tc_int_alias tc_int_alias2;

// ── Void return function ─────────────────────────────────────────

static inline void tc_noop(void) { }
static inline void tc_set_val(int *p, int v) { *p = v; }

// ── Pointer-to-bool and bool-to-int patterns ─────────────────────

static inline int tc_ptr_is_null(const void *p) { return p == NULL; }
static inline int tc_ptr_is_nonnull(const void *p) { return p != NULL; }
static inline int tc_bool_to_int(int cond) { return cond != 0; }
static inline int tc_sign(int v) { return -(v < 0); }

// ── Noreturn functions (Gap 1) ────────────────────────────────────

void tc_abort_noreturn(void) __attribute__((noreturn));
_Noreturn void tc_die_noreturn(void);

// ── Hex float literals (Gap 4) ───────────────────────────────────

#define TC_HEX_FLOAT_A 0x1.0p10
#define TC_HEX_FLOAT_B 0x1.0p5f
#define TC_HEX_FLOAT_C 0xAp0

// ── __builtin_choose_expr (Gap 5) ────────────────────────────────

#define TC_CHOOSE_TRUE(a, b) __builtin_choose_expr(1, a, b)
#define TC_CHOOSE_FALSE(a, b) __builtin_choose_expr(0, a, b)

// ── Circular struct forward declarations (Gap 6) ─────────────────

struct tc_node_a;
struct tc_node_b { struct tc_node_a *peer; int value; };
struct tc_node_a { struct tc_node_b *peer; int value; };

// ── _Atomic types (Gap 3) ────────────────────────────────────────

typedef _Atomic(int) tc_atomic_int;
typedef _Atomic(unsigned long) tc_atomic_ulong;

// ── Old-style function pointers (Gap 2) ──────────────────────────

typedef int (*tc_fn_old_style)();

#endif // TRANSLATE_C_TESTS_H
