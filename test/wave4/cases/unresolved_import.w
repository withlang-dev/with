// Error case: importing a module that does not exist.
// Expected: compiler exits with non-zero status and emits "import module not found".
use no.such.file

fn main -> i32:
    42
