// Test: migrator stub output for untranslatable functions.
// The translatable function should migrate normally.
// The untranslatable one should produce a [MIGRATOR_UNTRANSLATED] stub.

int translatable_add(int a, int b) {
    return a + b;
}

// Computed goto — cannot be represented in With
int untranslatable_dispatch(int op) {
    void *table[] = { &&L_ADD, &&L_SUB };
    goto *table[op];
L_ADD:
    return 1;
L_SUB:
    return 2;
}
