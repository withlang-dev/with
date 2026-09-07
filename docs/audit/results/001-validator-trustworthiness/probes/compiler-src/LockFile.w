// Compatibility facade for LockFile.
// Routes `use LockFile` to `src/compiler/LockFile.w`.

use compiler.LockFile

let _lock_file_facade_eof_guard = 0
