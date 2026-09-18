#define PCRE2_CODE_UNIT_WIDTH 8
#include <pcre2.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

static void trial(int set_limit) {
    char pat[700];
    int i, n = 0;
    for (i = 0; i < 300; i++) pat[n++] = '(';
    pat[n++] = 'a';
    for (i = 0; i < 300; i++) pat[n++] = ')';
    pat[n] = 0;
    int errcode;
    PCRE2_SIZE erroff;
    pcre2_general_context *g = pcre2_general_context_create(NULL, NULL, NULL);
    pcre2_compile_context *c = pcre2_compile_context_create(g);
    if (set_limit) pcre2_set_parens_nest_limit(c, 250);
    pcre2_code *re = pcre2_compile((PCRE2_SPTR)pat, PCRE2_ZERO_TERMINATED,
        0, &errcode, &erroff, c);
    printf("limit=%s code=%p err=%d off=%zu\n",
        set_limit ? "250" : "default",
        (void *)re, errcode, (size_t)erroff);
    if (re) pcre2_code_free(re);
    pcre2_compile_context_free(c);
    pcre2_general_context_free(g);
}

int main(void) {
    trial(0);
    trial(1);
    return 0;
}
