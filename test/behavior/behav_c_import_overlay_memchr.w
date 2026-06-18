//! expect-stdout: ok

// #379 buf_in: memchr is curated -- its (const void* s, size_t n) pair collapses
// into a single `[]u8`. Calling is safe (the slice length bounds the C read);
// the returned pointer is borrowed/nullable, deref stays unsafe.

use c_import("void *memchr(const void *s, int c, unsigned long n);\n")

fn main:
    let a = [104u8, 105u8, 106u8]   // "hij"
    let hit = memchr(a[0..3], 105)  // 'i'
    let miss = memchr(a[0..3], 122) // 'z'
    if miss != None:
        print("bad-miss")
        return
    if hit == None:
        print("bad-none")
        return
    let p = hit.unwrap() as *const u8
    if unsafe { *p } == 105:
        print("ok")
    else:
        print("bad")
