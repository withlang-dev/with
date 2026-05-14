// BuildGraphKinds -- stable build graph kind/platform metadata.

extern fn with_sysinfo_os() -> str
extern fn with_sysinfo_arch() -> str

const BUILD_GRAPH_KIND_MIN: i32 = 0
const BUILD_GRAPH_KIND_MAX: i32 = 43
const BUILD_GRAPH_TARGET_MIN: i32 = 0
const BUILD_GRAPH_TARGET_MAX: i32 = 5

pub fn build_graph_kind_valid(kind: i32) -> bool:
    kind >= BUILD_GRAPH_KIND_MIN and kind <= BUILD_GRAPH_KIND_MAX

pub fn build_graph_kind_name(kind: i32) -> str:
    if kind == 0: return "executable"
    if kind == 1: return "library"
    if kind == 2: return "test"
    if kind == 3: return "object"
    if kind == 4: return "archive"
    if kind == 5: return "generated_source"
    if kind == 6: return "generated_binary"
    if kind == 7: return "command"
    if kind == 8: return "install"
    if kind == 9: return "group"
    if kind == 10: return "binary_compare"
    if kind == 11: return "fixpoint_compare"
    if kind == 12: return "compile_c_object"
    if kind == 13: return "compile_asm_object"
    if kind == 14: return "compile_llvm_ir_object"
    if kind == 15: return "create_static_archive"
    if kind == 16: return "generate_response_file"
    if kind == 17: return "embed_object_files"
    if kind == 18: return "copy_runtime_tree"
    if kind == 19: return "run_corpus_test"
    if kind == 20: return "promote_tree_if_verified"
    if kind == 21: return "embedded_runtime_extract_test"
    if kind == 22: return "selfhost_noop_local_regression"
    if kind == 23: return "cli_selfhost_smoke_test"
    if kind == 24: return "generate_compiler_entrypoints"
    if kind == 25: return "with_compiler_build"
    if kind == 26: return "pcre2_run_test"
    if kind == 27: return "pcre2_generated_check"
    if kind == 28: return "pcre2_generated_promote"
    if kind == 29: return "pcre2_build"
    if kind == 30: return "cli_selfhost_one_liner_test"
    if kind == 31: return "cli_selfhost_object_symbol_test"
    if kind == 32: return "cli_selfhost_build_w_test"
    if kind == 33: return "generate_compat_runtime"
    if kind == 34: return "with_compiler_ir"
    if kind == 35: return "cli_selfhost_project_test"
    if kind == 36: return "cli_selfhost_edge_test"
    if kind == 37: return "cli_selfhost_pcre2_prep_test"
    if kind == 38: return "cli_selfhost_migrate_basic_test"
    if kind == 39: return "cli_selfhost_migrate_core_test"
    if kind == 40: return "selfhost_suite_test"
    if kind == 41: return "generate_llvm_link_metadata"
    if kind == 42: return "pcre2_reference_prepare"
    if kind == 43: return "pcre2_migrate"
    f"unknown({kind})"

pub fn build_graph_kind_implemented(kind: i32) -> bool:
    if kind >= 0 and kind <= 2:
        return true
    if kind >= 7 and kind <= BUILD_GRAPH_KIND_MAX:
        return true
    false

pub fn build_graph_target_valid(kind: i32) -> bool:
    kind >= BUILD_GRAPH_TARGET_MIN and kind <= BUILD_GRAPH_TARGET_MAX

pub fn build_graph_target_name(kind: i32) -> str:
    if kind == 0:
        return "native"
    if kind == 1:
        return "linux_x86_64"
    if kind == 2:
        return "linux_aarch64"
    if kind == 3:
        return "darwin_x86_64"
    if kind == 4:
        return "darwin_aarch64"
    if kind == 5:
        return "windows_x86_64"
    f"unknown({kind})"

pub fn build_graph_host_target_kind() -> i32:
    let os = with_sysinfo_os()
    let arch = with_sysinfo_arch()
    if os == "Macos":
        if arch == "armv8" or arch == "aarch64":
            return 4
        if arch == "x86_64":
            return 3
    if os == "Linux":
        if arch == "armv8" or arch == "aarch64":
            return 2
        if arch == "x86_64":
            return 1
    if os == "Windows":
        if arch == "x86_64":
            return 5
    0

pub fn build_graph_target_is_host(kind: i32) -> bool:
    if kind == 0:
        return true
    kind == build_graph_host_target_kind()
