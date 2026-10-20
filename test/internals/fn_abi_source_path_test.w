//! expect-stdout: ok

use FnAbi
use Resolve
use compiler.Runtime.runtime_cwd
use std.process

fn main:
    let saved = env("PWD")
    assert(set_env("PWD", "") == 0)
    let cwd = runtime_cwd()
    assert(cwd.len() > 0)
    // A canonical path is '/'-separated on every host: getcwd's `C:\a\b`
    // on Windows names `C:/a/b/src/FnAbi.w`.
    let expected = fn_abi_file_prefix_mapped(resolve_normalize_path(cwd) ++ "/src/FnAbi.w")
    assert(codegen_canonical_module_path("src/FnAbi.w") == expected)
    assert(set_env("PWD", saved) == 0)
    // A drive-letter path is absolute, never joined onto the cwd.
    assert(codegen_canonical_module_path("C:\\w\\src\\FnAbi.w") == "C:/w/src/FnAbi.w")
    // A prefix map spelled with Windows separators maps the canonical path.
    let saved_map = env("WITH_FILE_PREFIX_MAP")
    assert(set_env("WITH_FILE_PREFIX_MAP", "C:\\w=/mapped") == 0)
    assert(codegen_canonical_module_path("C:\\w\\src\\FnAbi.w") == "/mapped/src/FnAbi.w")
    assert(set_env("WITH_FILE_PREFIX_MAP", saved_map) == 0)
    print("ok")
