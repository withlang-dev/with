//! expect-check-fail: 'db_close' has no parameter named 'p'; its parameters are 0: d
//! expect-check-fail: = help: use one of those names, or the position: 'param 0'

// #3129: every contract refusal ends with the spelling that is accepted.
// A clause naming a parameter the function does not have.
use c_import("typedef struct db db;\ndb* db_new(int f);\nvoid db_close(db* d);\nconst char* util_msg(int code);\nint db_write(db* d, const unsigned char* p, unsigned long n);\ntypedef struct it_s { int n; } it_s;\nint it_init(it_s* s, int base);\nvoid it_end(it_s* s);\n")

c contract dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_close
        buffer param p len param n

fn main: print(1)
