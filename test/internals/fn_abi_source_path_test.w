//! expect-stdout: ok

use FnAbi
use compiler.Runtime.runtime_cwd
use std.process

fn main:
    let saved = env("PWD")
    assert(set_env("PWD", "") == 0)
    let cwd = runtime_cwd()
    assert(cwd.len() > 0)
    let expected = fn_abi_file_prefix_mapped(cwd ++ "/src/FnAbi.w")
    assert(codegen_canonical_module_path("src/FnAbi.w") == expected)
    assert(set_env("PWD", saved) == 0)
    print("ok")
