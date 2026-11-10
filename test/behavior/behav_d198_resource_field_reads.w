//! expect-stdout: 4 4 true | 7 9

// D198 (§16.2b.3): a field of a by-value or in-place resource's record is
// read through the resource. A read copies the field's value: a flat field
// its value, a pointer field the pointer, inert in safe code. It works
// through a borrow of the resource, and on an in-place resource it sees
// what C last wrote during a call.
use c_import("typedef struct { int *data; int n; } Img; static inline Img img_new(void) { Img i; i.data = 0; i.n = 4; return i; } static inline void img_free(Img i) { }
#define Z_OK 0
typedef struct { int state; int total; } z_stream;
static inline int z_init(z_stream* s, int start) { s->state = start; s->total = 0; return Z_OK; }
static inline void z_step(z_stream* s, int by) { s->total = s->total + by; }
static inline void z_end(z_stream* s) { s->state = 0; }
")

c facade imgs:
    resource Picture wraps Img
        from img_new
        drop img_free
    resource Stream wraps z_stream
        init z_init(self)
        ok Z_OK
        drop z_end
    fn z_step
        of Stream

fn width_of(p: &Picture) -> i32: p.n

fn main:
    let image = img_new()
    let data = image.data
    let Ok(strm) = Stream.init(7) else:
        print("init failed")
        return
    let state = strm.state
    strm.step(9)
    print(f"{image.n} {width_of(image)} {data == null} | {state} {strm.total}")
