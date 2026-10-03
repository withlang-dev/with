//! expect-stdout: 10
//! expect-stdout: 6

// §9.5 (#1930): a method declared in another module than its type's reaches
// the receiver's fields only through `self.`; the type's own module's
// methods reach them bare.

use receiver_field.owner

impl Meter:
    mut fn add(n: i32):
        self.reading += n

fn main:
    var m = Meter { reading: 3 }
    m.add(2)
    print(f"{m.doubled()}")
    m.add(-2)
    print(f"{m.doubled()}")
