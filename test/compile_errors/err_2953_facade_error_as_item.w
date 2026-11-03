//! expect-check-fail: a facade-wide error type is stated in the header, `c facade F error E:`, not as an item (§16.2b.4)

// #2953 (D97, §16.2b.4): `error E` belongs to the facade header. Written as
// an item, the refusal says where it goes.

use c_import("typedef struct kv kv;
#define KV_OK 0
int kv_open(const char* path, kv** out);
void kv_close(kv* k);
")

c facade kv:
    error KvError
    resource Store wraps *mut kv
        from kv_open(out param 1)
        drop kv_close
        ok KV_OK
