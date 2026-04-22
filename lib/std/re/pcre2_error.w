// Migrated from PCRE2
use std.re.defs

fn pcre2_get_error_message_8(enumber: c_int, buffer: *mut u8, size: c_ulong) -> c_int {
    var message: *const u8

    var i: c_ulong

    var n: c_int

    var rc: c_int = 0


    if ((if size == 0: 1 else: 0) != 0) {
        return -48
    }

    if ((if enumber >= 100: 1 else: 0) != 0) {
        (message = (&compile_error_texts[0] as *const u8))

        (n = enumber - 100)

    } else {
        if ((if enumber < 0: 1 else: 0) != 0) {
            (message = (&match_error_texts[0] as *const u8))

            (n = 0 - enumber)

        } else {
            (message = (("\0" as *const u8)))

            (n = 1)

        }
    }

    while ((if n > 0: 1 else: 0) != 0) {
        while true {
            var __ci_expr_old_0: *const u8 = message

            (message = message + 1)

            if (not ((if (unsafe: *__ci_expr_old_0) != 0: 1 else: 0) != 0)) {
                break
            }

        }

        if ((if (unsafe: *message) == 0: 1 else: 0) != 0) {
            return -29
        }


        (n = n - 1)

    }

    (i = 0)

    while ((if (unsafe: *message) != 0: 1 else: 0) != 0) {
        if ((if i >= (size -% 1): 1 else: 0) != 0) {
            (rc = -48)

            break

        }

        var __ci_expr_old_1: *const u8 = message

        (message = message + 1)

        ((unsafe: buffer[i]) = (unsafe: *__ci_expr_old_1))



        (i = i + 1)

    }


    ((unsafe: buffer[i]) = 0)

    var __ci_expr_ternary_2: c_int = 0

    if (rc != 0) {
        (__ci_expr_ternary_2 = rc)
    } else {
        (__ci_expr_ternary_2 = ((i as c_int)))
    }

    return __ci_expr_ternary_2


}
