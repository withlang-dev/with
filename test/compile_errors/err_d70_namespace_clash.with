//! expect-error: 'util' names two imports: `use d70.left.util` and `use d70.right.util`

// D70 (§18.2): two imports whose namespaces share a name. The imports are
// legal (bare LEVEL is the later one's); `util.LEVEL` cannot say which
// namespace it means, so it is an error that names both and offers `as`.

use d70.left.util
use d70.right.util

fn main:
    print(LEVEL)
    print(util.LEVEL)
