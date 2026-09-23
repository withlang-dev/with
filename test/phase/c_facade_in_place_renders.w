//! expect-check-stdout: ok

// D51 §16.2b.3/§16.2b.4: an in-place resource is rendered as ordinary With —
// `type R { repr, live }`, storage `Repr {}` or the `preinit` operation's
// result, `R.<init>` calling the C initializer over a pointer to the
// storage, Drop and each `destroys` operation passing the address of the
// representation — over prototype-only C, so this test only checks (phase
// lane). With `ok` the constructor is the Result projection (stage 5, Eric
// 2026-09-23 on #1426): `InflateStream.inflateInit()` is
// `Result[InflateStream, InflateStreamError]`, and the failed branch never
// holds an `InflateStream`; without `ok` a status-returning init yields
// `(status, R)`. Three resources wrap one representation (§14); `z_streamp`
// is the pointer typedef zlib spells, resolved through the alias.
// `InflateStream` and `DeflateStream` are pinned (a Box cell, D54); `Ctx` is
// `movable` and renders by value. Nothing here is `unsafe`. Constructors
// keep the C name; presentation (`InflateStream.init`) is §16.2b.11, stage 8.

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
        movable
        init ctx_init(self)
        drop ctx_end
    fn inflateReset
        destroys

fn inflate_reset() -> Result[c_int, InflateStreamError]:
    let inflater = InflateStream.inflateInit()?
    Ok(inflater.inflateReset(15))

fn main:
    let reset = match inflate_reset():
        Ok(r) => r
        Err(InflateStreamError.Failed(status)) => status
    let (dstatus, deflater) = DeflateStream.deflateInit(9, 6)
    let ctx = Ctx.ctx_init()
    let held: Vec[DeflateStream] = Vec.new()
    held.push(deflater)
    print(f"{reset} {dstatus} {ctx.live}")
