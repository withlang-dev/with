//! expect-error: ephemeral value borrows a temporary that dies at the end of this statement

// #3004 (D186, §13.3, §21.1): `zip` accepts an iterable argument by inserting
// `.iter()`; passing a temporary collection literal and binding the resulting
// `Zip` iterator leaves it borrowing dead temporary storage.

fn main:
    let xs = [10, 20]
    var z = xs.iter().zip([1, 2])
    print(z.next().is_some())
