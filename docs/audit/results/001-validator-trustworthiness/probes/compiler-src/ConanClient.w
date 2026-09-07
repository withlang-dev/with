// Compatibility facade for ConanClient.
// Routes `use ConanClient` to `src/compiler/ConanClient.w`.

use compiler.ConanClient

let _conan_client_facade_eof_guard = 0
