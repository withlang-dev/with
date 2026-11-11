//! expect-stdout: 13

// A file-scope `static` variable in an imported header is that translation
// unit's own: the header defines it. It was emitted as `extern var`, a
// reference to a symbol no object has ("undefined symbol: _cells").
use c_import("static int cells[4]; static int count; static inline void put(int v) { cells[count] = v; count = count + 1; } static inline int total(void) { return cells[0] + cells[1] + count; }")

fn main:
    put(5)
    put(6)
    print(f"{total()}")
