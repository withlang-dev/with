//! expect-check-fail: as_mut_ptr() needs a slice that may be written: this one is read-only
//! expect-check-fail: = help: use as_ptr(), or take the slice as `[]mut`

// #3130: a read-only slice hands out no pointer to write through.
fn poke(v: []u8):
    let p = v.as_mut_ptr()
    unsafe { *p = 1 }

fn main:
    let xs: List[u8] = [1, 2]
    poke(xs)
