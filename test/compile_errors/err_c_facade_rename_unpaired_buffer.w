//! expect-check-fail: is a raw pointer that no clause pairs, so it is not a buffer; a presented operation renders no call without a bounds contract

// D64 §16.2b.8: a raw pointer parameter that no clause pairs is not a
// buffer, and a presentation clause on such a function is refused. Here a
// `rename` on a function whose first parameter is a handle no resource
// wraps (a byte or scalar pointer is err_c_facade_lend_unpaired_buffer's):
// the refusal names the parameter and the clauses that would pair or bind
// it.
use c_import("typedef struct db db;\nint db_count(db *d, int flags);\n")

c facade dbl:
    fn db_count
        rename count

fn main:
    print("unreachable")
