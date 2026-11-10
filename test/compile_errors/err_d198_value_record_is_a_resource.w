//! expect-check-fail: the record is a resource's representation, so the operation borrows that resource; it is not a value record (§16.2b.5)
// D198 (§16.2b.5): a pointer to the representation of an in-place resource is
// not a value record: the operation borrows that resource.
use c_import("typedef struct { int level; } stream; static inline int stream_init(stream *s) { s->level = 1; return 0; } static inline void stream_end(stream *s) { s->level = 0; } static inline int stream_level(const stream *s) { return s->level; }")

c facade streams:
    resource Stream wraps stream
        init stream_init(self)
        drop stream_end
    fn stream_level
        reads param s

fn main:
    print("unreachable")
