#ifndef COERCION_TEST_H
#define COERCION_TEST_H

static inline void* coercion_get_str(void) {
    return (void*)"hello from C";
}

static inline void* coercion_get_null(void) {
    return (void*)0;
}

static inline int coercion_bool_to_int(int val) {
    return val;
}

#endif
