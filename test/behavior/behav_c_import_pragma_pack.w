//! expect-stdout: bmp_file_header: size 14/14 align 2/2
//! expect-stdout: bmp_file_header offsets: 0 2 6 8 10
//! expect-stdout: with-built bytes agree with clang's offsets: true
//! expect-stdout: c-filled: type=19778 size=287454020 r1=7 r2=9 off=54
//! expect-stdout: c reads the with-built bfSize: 287454020
//! expect-stdout: pack2_mixed: size 12/12 align 2/2 value=2.5 count=3
//! expect-stdout: pack4_wide: size 16/16 align 4/4 ll=81985529216486895 d=100
//! expect-stdout: holder: size 18/18 align 2/2 c=97 h.bfSize=287454020 d=122
//! expect-stdout: ok

// Spec §16.4 (D71, #1421): `@[repr(packed(N))]` caps every field's
// alignment at N and the record's at N — the layout of C's
// `#pragma pack(N)` — and c_import emits it for such records, which it
// imported opaque before (#1396). Checked against clang for each record:
// size_of/align_of against sizeof/_Alignof, every field offset against
// offsetof (clang evaluates them as enum constants; the bytes a With-built
// value holds sit at those offsets), a value C fills read field by field
// in With, and one With builds read in C. `holder` is an ordinary record
// embedding a pack(2) one: its field lands at the pack(2) record's
// alignment, 2, as C places it.

use c_import("#include <stddef.h>
#pragma pack(push, 2)
typedef struct bmp_file_header {
    unsigned short bfType;
    unsigned int bfSize;
    unsigned short bfReserved1;
    unsigned short bfReserved2;
    unsigned int bfOffBits;
} bmp_file_header;
typedef struct pack2_mixed { char tag; double value; short count; } pack2_mixed;
#pragma pack(pop)
#pragma pack(push, 4)
typedef struct pack4_wide { char c; long long ll; char d; } pack4_wide;
#pragma pack(pop)
typedef struct holder { char c; bmp_file_header h; char d; } holder;
enum {
    BMP_SIZE = sizeof(bmp_file_header), BMP_ALIGN = _Alignof(bmp_file_header),
    BMP_OFF_TYPE = offsetof(bmp_file_header, bfType), BMP_OFF_SIZE = offsetof(bmp_file_header, bfSize),
    BMP_OFF_R1 = offsetof(bmp_file_header, bfReserved1), BMP_OFF_R2 = offsetof(bmp_file_header, bfReserved2),
    BMP_OFF_BITS = offsetof(bmp_file_header, bfOffBits),
    MIXED_SIZE = sizeof(pack2_mixed), MIXED_ALIGN = _Alignof(pack2_mixed),
    WIDE_SIZE = sizeof(pack4_wide), WIDE_ALIGN = _Alignof(pack4_wide),
    HOLDER_SIZE = sizeof(holder), HOLDER_ALIGN = _Alignof(holder)
};
static inline unsigned char byte_at(const void *p, int i) { return ((const unsigned char *)p)[i]; }
static inline void fill_bmp(bmp_file_header *h) { h->bfType = 0x4D42; h->bfSize = 0x11223344; h->bfReserved1 = 7; h->bfReserved2 = 9; h->bfOffBits = 54; }
static inline unsigned int read_bmp_size(const bmp_file_header *h) { return h->bfSize; }
static inline void fill_mixed(pack2_mixed *m) { m->tag = 'm'; m->value = 2.5; m->count = 3; }
static inline void fill_wide(pack4_wide *w) { w->c = 1; w->ll = 0x0123456789ABCDEFLL; w->d = 100; }
static inline void fill_holder(holder *x) { x->c = 'a'; fill_bmp(&x->h); x->d = 'z'; }
")

fn main:
    print(f"bmp_file_header: size {size_of[bmp_file_header]()}/{BMP_SIZE} align {align_of[bmp_file_header]()}/{BMP_ALIGN}")
    print(f"bmp_file_header offsets: {BMP_OFF_TYPE} {BMP_OFF_SIZE} {BMP_OFF_R1} {BMP_OFF_R2} {BMP_OFF_BITS}")
    // Built in With: each field's little-endian bytes sit where clang puts
    // the field.
    let built = bmp_file_header { bfType: 0x4D42, bfSize: 0x11223344, bfReserved1: 7, bfReserved2: 9, bfOffBits: 54 }
    let p = (&raw const built) as *const c_void
    let agree = unsafe { byte_at(p, BMP_OFF_TYPE) == 0x42 and byte_at(p, BMP_OFF_TYPE + 1) == 0x4D and byte_at(p, BMP_OFF_SIZE) == 0x44 and byte_at(p, BMP_OFF_SIZE + 3) == 0x11 and byte_at(p, BMP_OFF_R1) == 7 and byte_at(p, BMP_OFF_R2) == 9 and byte_at(p, BMP_OFF_BITS) == 54 }
    print(f"with-built bytes agree with clang's offsets: {agree}")
    var filled = bmp_file_header { bfType: 0, bfSize: 0, bfReserved1: 0, bfReserved2: 0, bfOffBits: 0 }
    unsafe { fill_bmp(&raw mut filled) }
    print(f"c-filled: type={filled.bfType} size={filled.bfSize} r1={filled.bfReserved1} r2={filled.bfReserved2} off={filled.bfOffBits}")
    print(f"c reads the with-built bfSize: {unsafe { read_bmp_size(&raw const built) }}")

    var m = pack2_mixed { tag: 0, value: 0.0, count: 0 }
    unsafe { fill_mixed(&raw mut m) }
    print(f"pack2_mixed: size {size_of[pack2_mixed]()}/{MIXED_SIZE} align {align_of[pack2_mixed]()}/{MIXED_ALIGN} value={m.value} count={m.count}")

    var w = pack4_wide { c: 0, ll: 0, d: 0 }
    unsafe { fill_wide(&raw mut w) }
    print(f"pack4_wide: size {size_of[pack4_wide]()}/{WIDE_SIZE} align {align_of[pack4_wide]()}/{WIDE_ALIGN} ll={w.ll} d={w.d}")

    var x = holder { c: 0, h: bmp_file_header { bfType: 0, bfSize: 0, bfReserved1: 0, bfReserved2: 0, bfOffBits: 0 }, d: 0 }
    unsafe { fill_holder(&raw mut x) }
    print(f"holder: size {size_of[holder]()}/{HOLDER_SIZE} align {align_of[holder]()}/{HOLDER_ALIGN} c={x.c} h.bfSize={x.h.bfSize} d={x.d}")
    print("ok")
