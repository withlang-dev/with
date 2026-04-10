// Stubs for PCRE2 JIT functions — JIT is not included in the
// With-migrated PCRE2 library. These return appropriate error
// codes so pcre2test can run non-JIT tests.

#include <stddef.h>

typedef unsigned int uint32_t;
typedef unsigned long size_t;

// PCRE2_ERROR_JIT_BADOPTION
#define PCRE2_ERROR_JIT_BADOPTION (-45)

int pcre2_jit_compile_8(void *code, uint32_t options) {
    (void)code; (void)options;
    return PCRE2_ERROR_JIT_BADOPTION;
}

int pcre2_jit_match_8(void *code, const void *subject, size_t length,
    size_t startoffset, uint32_t options, void *match_data, void *mcontext) {
    (void)code; (void)subject; (void)length;
    (void)startoffset; (void)options; (void)match_data; (void)mcontext;
    return PCRE2_ERROR_JIT_BADOPTION;
}

void pcre2_jit_free_unused_memory_8(void *gcontext) {
    (void)gcontext;
}

void *pcre2_jit_stack_create_8(size_t startsize, size_t maxsize, void *gcontext) {
    (void)startsize; (void)maxsize; (void)gcontext;
    return NULL;
}

void pcre2_jit_stack_assign_8(void *mcontext, void *callback, void *data) {
    (void)mcontext; (void)callback; (void)data;
}

void pcre2_jit_stack_free_8(void *stack) {
    (void)stack;
}

size_t pcre2_jit_get_size_8(void *code) {
    (void)code;
    return 0;
}

const char *pcre2_jit_get_target_8(void) {
    return "none (JIT not available)";
}
