//! expect-error: `total` is read before its statement has run

// D184 (§29.15): a script's binding is assigned where its statement stands;
// a helper that reads it, called before that line, is a compile-time error
// (D175's static graph).

fn show(): print(total)
show()
let total = 5
print(total)
