//! expect-check-fail: facade states one error type 'KvError', whose status is one type, but 'kv_open' returns c_int and 'kv_flush' returns c_long

// #2179 (D97, spec §16.2b.4): `c facade kv error KvError` gives every `ok`
// operation of the facade one error, whose `Failed(status)` holds one status
// type. A producer whose status is an `int` and an operation whose status is
// a `long` cannot share it; the error names both.

use c_import("typedef struct kv kv;
#define KV_OK 0
int kv_open(const char* path, kv** out);
void kv_close(kv* k);
long kv_flush(kv* k);
")

c facade kv error KvError:
    resource Store wraps *mut kv
        from kv_open(out param 1)
        drop kv_close
        ok KV_OK
    fn kv_flush
        lend
        ok KV_OK

fn main:
    print("ok")
