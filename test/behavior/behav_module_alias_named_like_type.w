//! expect-stdout: ok

use pre_d_build_runner

// §18.2 (#1708): imports are not transitive, so a module that only imports
// another (`Comp.w`: `use cu`) re-exports nothing. `use Comp; Comp.init()`
// names the module alias `Comp`, not the type `Comp` that `cu` declares.
// check_qualified_extension_call claimed every `alias.m()` whose alias
// matched, and reported "qualified extension method 'Comp.init' requires a
// receiver argument" for a method no module declares (the compiler's own
// src/Compilation.w shim hit it five times in Lsp.w). When the module
// declares no extension method of that name and a type `Comp` exists that
// this module cannot see, the diagnostic names that type; an alias with no
// such type keeps "unknown qualified extension method"
// (err_extension_method_unknown_qualified).
fn main:
    let case_dir = p7_prepare_case("module_alias_named_like_type", "aliastype")
    p7_write(case_dir, "cu.w", "pub type Comp { n: i32 }
pub fn Comp.init -> Comp: Comp { n: 1 }
")
    p7_write(case_dir, "Comp.w", "use cu
")
    p7_write(case_dir, "p1.w", "use Comp
fn main:
    let x = Comp.init()
    print(f\"{x.n}\")
")
    p7_write(case_dir, "p2.w", "use cu
fn main:
    let x = Comp.init()
    print(f\"{x.n}\")
")
    let via_alias = p7_run(case_dir, "alias-named-like-type", "check\0p1.w\0")
    p7_assert_failure_contains(via_alias, "symbol 'Comp' is not visible from this module", "check p1.w")
    assert(not via_alias.stderr.contains("requires a receiver argument"))
    let direct = p7_run(case_dir, "alias-direct-import", "check\0p2.w\0")
    p7_assert_success(direct, "check p2.w")
    print("ok")
