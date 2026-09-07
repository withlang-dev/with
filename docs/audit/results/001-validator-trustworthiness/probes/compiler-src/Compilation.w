// Compatibility facade for the self-hosted compiler orchestration root.
//
// Keep `use Compilation` stable for existing call sites while routing all
// behavior through `src/compiler/Compilation.w`.

use compiler.Compilation

let _compilation_facade_eof_guard = 0
