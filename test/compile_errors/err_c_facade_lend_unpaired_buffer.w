//! expect-check-fail: fn 'compress': a lend would make the call safe, but param 0: *mut u8 dest is a caller-owned buffer that needs a length contract, and no clause states one yet (#1621)

// D51 stage 12b (#1621; spec §16.2b.3, §16.2b.5, §16.2b.8): a `lend` on a
// function whose parameters include a caller-owned buffer and its length
// — zlib's `compress(Bytef *dest, uLongf *destLen, const Bytef *source,
// uLong sourceLen)` — asserted only "not retained, consumed or
// destroyed", and rendered a safe call over raw pointers with no bounds
// contract: a caller passing a capacity larger than its array corrupted
// memory in safe code. No clause pairs a buffer with its length yet, so
// the item is refused, naming the first uncovered pointer, and the call
// stays raw.
use c_import("typedef unsigned char Bytef;
typedef unsigned long uLong;
typedef unsigned long uLongf;
int compress(Bytef *dest, uLongf *destLen, const Bytef *source, uLong sourceLen);
const char *zlibVersion(void);
")

c facade zlib:
    fn compress
        lend
    fn zlibVersion
        returns static CStr

fn main:
    print("unreachable")
