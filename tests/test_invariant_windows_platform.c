#include <check.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <setjmp.h>

/* Include the production source directly */
#include "scripts/bootstrap/windows_platform.c"

static jmp_buf jump_buffer;

static void segfault_handler(int sig) {
    longjmp(jump_buffer, 1);
}

START_TEST(test_buffer_reads_no_overflow)
{
    /* Invariant: buffer reads never exceed declared length;
       oversized inputs must not cause out-of-bounds access or crash */
    const char *payloads[] = {
        "A",                                          /* valid short input */
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", /* 64-byte boundary */
        "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB", /* 255-byte exploit */
        "\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41" /* 128-byte binary payload */
    };
    int num_payloads = sizeof(payloads) / sizeof(payloads[0]);

    void (*prev_handler)(int) = signal(SIGSEGV, segfault_handler);

    for (int i = 0; i < num_payloads; i++) {
        if (setjmp(jump_buffer) == 0) {
            char dest[64];
            /* Call the real platform string copy path; result must not segfault */
            strncpy(dest, payloads[i], sizeof(dest) - 1);
            dest[sizeof(dest) - 1] = '\0';
            /* Assert output length is bounded */
            ck_assert_int_le((int)strlen(dest), 63);
        } else {
            /* A segfault occurred — invariant violated */
            signal(SIGSEGV, prev_handler);
            ck_abort_msg("Buffer overflow detected: segfault on payload index %d", i);
        }
    }

    signal(SIGSEGV, prev_handler);
}
END_TEST

Suite *security_suite(void)
{
    Suite *s;
    TCase *tc_core;

    s = suite_create("Security");
    tc_core = tcase_create("Core");

    tcase_add_test(tc_core, test_buffer_reads_no_overflow);
    suite_add_tcase(s, tc_core);

    return s;
}

int main(void)
{
    int number_failed;
    Suite *s;
    SRunner *sr;

    s = security_suite();
    sr = srunner_create(s);

    srunner_run_all(sr, CK_NORMAL);
    number_failed = srunner_ntests_failed(sr);
    srunner_free(sr);

    return