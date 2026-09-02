// FnAbi — the With ABI's rules, in one ABI-owned module (docs/with-abi.md,
// decisions.md D6 and D38).
//
// Everything here is a pure rule over already-computed facts: which pass
// mode a parameter gets, when a platform forces an aggregate indirect, how a
// function's link name is formed. Codegen keeps one-line adapters that feed
// these rules their inputs; the rules never live per-path (D6: the
// transparent T*/T** bug was a per-path re-derivation).
//
// This file and src/TypeLayout.w are the ABI-defining sources: their sha256
// (recorded in docs/with-abi.sha256, checked by the abi-hash-check battery
// target) keys every .wo bundle's object (docs/abi_roadmap.md, Level 0), so
// an edit here rebuilds every bundle once, automatically, and an ABI rule
// cannot drift into an unhashed file unnoticed.
use Resolve

extern fn with_str_clone_ref(s: &str) -> str
extern fn with_str_hash(s: &str) -> u64
extern fn with_getenv_str(name: &str) -> str

// A label for docs/with-abi.md's version history, not the bundle key; it
// becomes a frozen, normative major version at Level 1 of the roadmap.
pub const WITH_ABI_VERSION: i32 = 1

// #D6: PassMode — the per-parameter ABI classification, the SINGLE source of
// truth. fn_abi_pass_mode computes it; both the callee prologue
// (declare_function_from_sig) and every call site read it, so caller and
// callee can never disagree on how an argument is passed.
//   PM_DIRECT         = by value (Copy / scalar / small aggregate)
//   PM_INDIRECT       = pointer to a callee-owned copy (byval, Windows-x86_64)
//   PM_INDIRECT_PLACE = pointer to the CALLER's place (share-place / value_ref_abi)
pub const PM_DIRECT: i32 = 0
pub const PM_INDIRECT: i32 = 1
pub const PM_INDIRECT_PLACE: i32 = 2

// The classifier. `uses_value_ref_abi` is Sema's finalized share-place
// verdict for the parameter; `platform_indirect` is the platform's answer
// for the parameter's LLVM type (fn_abi_platform_aggregate_indirect).
pub fn fn_abi_pass_mode(uses_value_ref_abi: i32, platform_indirect: bool) -> i32:
    if uses_value_ref_abi != 0:
        return PM_INDIRECT_PLACE
    if platform_indirect:
        return PM_INDIRECT
    PM_DIRECT

// The one platform exception in v1: windows-x86_64 passes and returns a
// struct or array larger than 8 bytes indirectly (byval / sret). Every other
// target passes aggregates by LLVM value and lets LLVM lower them.
pub fn fn_abi_platform_aggregate_indirect(windows_x86_64: bool, is_aggregate: bool, size: i64) -> bool:
    windows_x86_64 and is_aggregate and size > 8

// ── Symbols ─────────────────────────────────────────────────────────────

// A function whose symbol has no text (synthesized) links as __fn_<sym>.
pub fn fn_abi_anonymous_symbol(sym: i32) -> str: f"__fn_{sym}"

pub fn codegen_hash_name_component(value: i64) -> str:
    if value < 0:
        return "n" ++ f"{0 - value}"
    f"{value}"

// "lib/std/re/x.w" or ".../lib/std/re/x.w" → "std/re/x.w"; "" for any other
// path. The same three spellings Sema's module naming accepts.
fn fn_abi_std_tree_relative(path: &str) -> str:
    if path.starts_with("lib/std/"):
        return path.slice("lib/".len(), path.len())
    let marker = "/lib/std/"
    var i = 0 as i64
    while i + marker.len() <= path.len():
        if path.slice(i, i + marker.len()) == marker:
            return path.slice(i + "/lib/".len(), path.len())
        i = i + 1
    ""

pub fn codegen_canonical_module_path(path: &str) -> str:
    if path.len() == 0 or path == "<unknown>":
        return with_str_clone_ref(path)
    if path.byte_at(0) == '<':
        return with_str_clone_ref(path)
    // A stdlib module resolved from a checkout's tree is the module its
    // embedded copy is (Sema names both `std.x`), so its canonical path is
    // the embedded spelling: a .wo built from the tree hashes the same
    // symbols as one built from any checkout, never `$PWD` (D38).
    let std_rel = fn_abi_std_tree_relative(path)
    if std_rel.len() > 0:
        return "<embedded-std>/" ++ std_rel
    if path.byte_at(0) == '/':
        return resolve_normalize_path(path)
    let cwd = with_getenv_str("PWD")
    if cwd.len() == 0:
        return resolve_normalize_path(path)
    resolve_join(cwd, path)

pub fn codegen_is_runtime_source_file(source_path: &str) -> bool:
    source_path.starts_with("rt/") or source_path.contains("/rt/") or
        source_path.starts_with("rt\\") or source_path.contains("\\rt\\") or
        source_path == "out/gen/compat_runtime.w" or
        source_path == "out\\gen\\compat_runtime.w" or
        source_path.ends_with("/out/gen/compat_runtime.w") or
        source_path.ends_with("\\out\\gen\\compat_runtime.w")

pub fn codegen_is_runtime_abi_symbol(base_name: &str) -> bool:
    if base_name.starts_with("with_") or base_name.starts_with("rt_") or base_name.starts_with("wl_"):
        return true
    base_name == "__error" or base_name == "__open" or
        base_name == "gethostname" or base_name == "pthread_self" or
        base_name == "mkstemp" or base_name == "realpath" or
        base_name == "i32_to_str" or base_name == "i64_to_string" or
        base_name == "str_from_byte"

pub fn codegen_preserve_runtime_link_name(source_path: &str, base_name: &str) -> bool:
    codegen_is_runtime_source_file(source_path) and codegen_is_runtime_abi_symbol(base_name)

// The prefix every module-qualified symbol of `source_path` carries:
// `__with_mod_<hash(canonical module path)>__`. A .wo bundle's manifest lists
// one per module; an undefined symbol starting with it is that bundle's.
pub fn fn_abi_module_link_prefix(source_path: &str) -> str:
    let canonical_path = codegen_canonical_module_path(source_path)
    if canonical_path.len() == 0 or canonical_path == "<unknown>":
        return ""
    "__with_mod_" ++ codegen_hash_name_component(with_str_hash(canonical_path) as i64) ++ "__"

// A function's link name when objects are built per module:
// __with_mod_<hash(canonical module path)>__<base>. Runtime ABI symbols keep
// their bare names; whole-program mode keeps every base name.
pub fn fn_abi_module_link_name(module_object_mode: i32, source_path: &str, base_name: &str) -> str:
    if module_object_mode == 0:
        return with_str_clone_ref(base_name)
    if codegen_preserve_runtime_link_name(source_path, base_name):
        return with_str_clone_ref(base_name)
    let canonical_path = codegen_canonical_module_path(source_path)
    if canonical_path.len() == 0 or canonical_path == "<unknown>":
        return with_str_clone_ref(base_name)
    "__with_mod_" ++ codegen_hash_name_component(with_str_hash(canonical_path) as i64) ++ "__" ++ base_name
