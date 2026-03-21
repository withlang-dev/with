// translate_c_tests.c — C implementations for translate-c test header

#include "translate_c_tests.h"
#include <string.h>

int tc_add(int a, int b) { return a + b; }
int tc_mul(int a, int b) { return a * b; }

void tc_swap(int *a, int *b) {
    int tmp = *a;
    *a = *b;
    *b = tmp;
}

int tc_abs(int x) { return x < 0 ? -x : x; }
const char *tc_greeting(void) { return "hello from C"; }

size_t tc_strlen_custom(const char *s) {
    size_t len = 0;
    while (s[len]) len++;
    return len;
}

int tc_global_counter = 0;
const int tc_global_const = 42;

int tc_ptr_is_null(const void *p) { return p == NULL; }
int tc_ptr_is_nonnull(const void *p) { return p != NULL; }
int tc_bool_to_int(int cond) { return cond != 0; }
int tc_sign(int v) { return -(v < 0); }
