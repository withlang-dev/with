//! check-only

// Behavior test: for-loop destructuring (spec SS9.7)
// TODO: for (key, val) in map: destructuring not yet implemented.
// TODO: Pattern matching in function parameters not yet supported.

fn main:
    // Basic for loop works
    var sum = 0
    for i in 0..5:
        sum += i
    assert(sum == 10)
