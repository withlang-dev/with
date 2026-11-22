//! expect-stdout: 7 0
//! expect-stdout: 65 66 0
//! expect-stdout: 5 5

// §4.3c (D119): a never-grown List literal lives in the frame, and only a
// constant nothing writes in place is static data. A borrow of an element
// cast to a raw pointer is such a write (the address a C call fills, as the
// migrator spells `fread(buf, 1, sizeof buf, f)`): the elements stay in the
// frame, so the write lands and the next read sees it. Before this, the
// buffer was a static constant: the write hit read-only data (a bus error
// in memset) or the read was folded to the literal's zero.

unsafe fn fill(p: *mut i8, n: i32):
    for i in 0..n: *(p + i) = (65 + i) as i8

fn main:
    var buf: List[i8] = [0; 16]
    unsafe:
        let p = &buf[0] as *mut i8
        *p = 7
    print(f"{buf[0] as i32} {buf[1] as i32}")
    var text: List[i8] = [0; 8]
    unsafe { fill(&text[0] as *mut i8, 2) }
    print(f"{text[0] as i32} {text[1] as i32} {text[2] as i32}")
    // A constant table read through a pointer keeps its value too.
    let table: List[i32] = [5, 6, 7]
    var seen = 0
    unsafe:
        let q = &table[0] as *const i32
        seen = *q
    print(f"{seen} {table[0]}")
