//! expect-check-fail: fn 'it_init': an initializer takes only what the resource passes it; a fixed argument on 'it_init' is not modeled
//! expect-check-fail: = help: delete 'param N fixed …' under 'fn it_init'

// #3129: every contract refusal ends with the spelling that is accepted.
// A fixed argument on an in-place initializer.
use c_import("typedef struct db db;\ndb* db_new(int f);\nvoid db_close(db* d);\nconst char* util_msg(int code);\nint db_write(db* d, const unsigned char* p, unsigned long n);\ntypedef struct it_s { int n; } it_s;\nint it_init(it_s* s, int base);\nvoid it_end(it_s* s);\n")

c contract dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close
    resource Iter wraps it_s
        init it_init(self)
        drop it_end
    fn it_init
        param base fixed 1

fn main: print(1)
