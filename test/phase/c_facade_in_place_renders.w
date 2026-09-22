//! expect-check-stdout: ok

// D51 §16.2b.3/§16.2b.4 stage 4b: an in-place resource is rendered as
// ordinary With — `type R { repr, live }`, storage `Repr {}` or the
// `preinit` operation's result, `R.<init>` calling the C initializer over a
// pointer to the storage and arming Drop by the `ok` status, Drop and each
// `destroys` operation passing the address of the representation — over
// prototype-only C, so this test only checks (phase lane). Two resources
// wrap one representation (§14); `z_streamp` is the pointer typedef zlib
// spells, resolved through the alias. Nothing here is `unsafe`.

use c_import("typedef struct { int state; } z_stream;
typedef z_stream *z_streamp;
#define Z_OK 0
int inflateInit(z_streamp s);
int inflateEnd(z_streamp s);
int inflateReset(z_stream* s, int windowBits);
z_stream deflate_storage(int mode);
int deflateInit(z_stream* s, int level);
void deflateEnd(z_stream* s);
void ctx_init(z_stream* s);
void ctx_end(z_stream* s);
")

c facade zlib:
    resource InflateStream wraps z_stream
        init inflateInit(self)
        ok Z_OK
        drop inflateEnd
        destroys inflateReset
    resource DeflateStream wraps z_stream
        preinit deflate_storage
        init deflateInit(self)
        drop deflateEnd
    resource Ctx wraps z_stream
        init ctx_init(self)
        drop ctx_end
    fn inflateReset
        destroys

fn main:
    let (status, inflater) = InflateStream.inflateInit()
    let reset = inflater.inflateReset(15)
    let (dstatus, deflater) = DeflateStream.deflateInit(9, 6)
    let ctx = Ctx.ctx_init()
    let held: Vec[DeflateStream] = Vec.new()
    held.push(deflater)
    print(f"{status} {reset} {dstatus} {ctx.live}")
