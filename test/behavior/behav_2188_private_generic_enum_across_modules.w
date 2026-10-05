//! expect-stdout: true
// #2188: a private generic enum, instantiated through another module's
// public type, reflects its variants through the instance's template, not
// a name visible from here.
use lib.private_generic_enum

let h = Holder.first(3)
print(h.is_one())
