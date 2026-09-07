/* optbit_oracle.c — independent oracle for raw compile-option bits.
 * Calls the SYSTEM libpcre2-8 (10.47) pcre2_compile_8 with an explicit
 * options word and prints accept/reject + code/offset/message. Used for
 * cases pcre2test cannot express (raw undefined bit 0x10000000).
 * Build: cc optbit_oracle.c -o optbit_oracle -I<brew>/include -L<brew>/lib -lpcre2-8
 */
#include <stdio.h>
#include <string.h>
#define PCRE2_CODE_UNIT_WIDTH 8
#include <pcre2.h>

static void one(const char *tag, const char *pat, uint32_t opts) {
    int code;
    PCRE2_SIZE off;
    pcre2_code_8 *re = pcre2_compile_8(
        (PCRE2_SPTR8)pat, PCRE2_ZERO_TERMINATED, opts, &code, &off, NULL);
    if (re == NULL) {
        PCRE2_UCHAR8 buf[256];
        pcre2_get_error_message_8(code, buf, sizeof(buf));
        printf("%s COMPILE_FAIL code=%d off=%zu msg=%s\n", tag, code,
               (size_t)off, buf);
    } else {
        printf("%s COMPILE_OK\n", tag);
        pcre2_code_free_8(re);
    }
}

int main(void) {
    one("bad-optbit", "a", 0x10000000u);
    one("sanity-anchored-bit", "a", 0x80000000u);
    one("sanity-zero", "a", 0u);
    return 0;
}
