#define PCRE2_CODE_UNIT_WIDTH 8
#include <pcre2.h>
#include <stdio.h>
#include <string.h>

static void run(int idx, const char *pat, const char *subj) {
    int err; PCRE2_SIZE off;
    pcre2_code *re = pcre2_compile((PCRE2_SPTR)pat, PCRE2_ZERO_TERMINATED,
        0, &err, &off, NULL);
    if (!re) { printf("DFA %d COMPILEFAIL %d %zu\n", idx, err, off); return; }
    pcre2_match_data *md = pcre2_match_data_create_from_pattern(re, NULL);
    int ws[100] = {0};
    int rc = pcre2_dfa_match(re, (PCRE2_SPTR)subj, strlen(subj), 0, 0,
        md, NULL, ws, 100);
    printf("DFA %d RC %d OVCOUNT %u WS", idx, rc, pcre2_get_ovector_count(md));
    for (int i = 0; i < 8; i++) printf(" %d", ws[i]);
    printf(" RAW");
    /* md.rc is internal; print ovector pairs 0..3, UNSET as U */
    PCRE2_SIZE *ov = pcre2_get_ovector_pointer(md);
    for (int i = 0; i < 4; i++) {
        if (ov[i*2] == PCRE2_UNSET) printf(" U");
        else printf(" %zu:%zu", ov[i*2], ov[i*2+1]);
    }
    printf("\n");
    pcre2_match_data_free(md);
    pcre2_code_free(re);
}

int main(void) {
    run(0, "a|ab", "ab");
    run(1, "(ab|a)(c)", "abc");
    run(2, "foo|foobar", "xfoobarx");
    run(3, "a+", "bbb");
    return 0;
}
