//! expect-error: `reading` is a field of the receiver; a method declared outside its type's module reaches it only as `self.reading` (§9.5)

// §9.5 (#1930): a method declared in another module than its type's does
// not reach the receiver's fields by bare name.

use receiver_field.owner

impl Meter:
    fn tripled -> i32: reading * 3

fn main:
    let m = Meter { reading: 3 }
    print(f"{m.tripled()}")
