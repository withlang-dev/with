// BuildGraphKinds -- stable build graph kind/platform metadata.

extern fn with_sysinfo_os() -> str
extern fn with_sysinfo_arch() -> str

const BUILD_GRAPH_STANDARD_KIND_MIN: i32 = 0
const BUILD_GRAPH_STANDARD_KIND_MAX: i32 = 23
const BUILD_GRAPH_PROJECT_KIND_MIN: i32 = 1000
const BUILD_GRAPH_PROJECT_KIND_MAX: i32 = 1027
const BUILD_GRAPH_TARGET_MIN: i32 = 0
const BUILD_GRAPH_TARGET_MAX: i32 = 5

fn build_graph_kind_is_standard(kind: i32) -> bool:
    if kind >= BUILD_GRAPH_STANDARD_KIND_MIN and kind <= 4:
        return true
    kind >= 7 and kind <= BUILD_GRAPH_STANDARD_KIND_MAX

fn build_graph_kind_is_project(kind: i32) -> bool:
    false

pub fn build_graph_kind_removed(kind: i32) -> bool:
    kind == 5 or kind == 6 or kind == 1000 or kind == 1001 or kind == 1002 or kind == 1003 or kind == 1004 or kind == 1005 or kind == 1006 or kind == 1007 or kind == 1008 or kind == 1009 or kind == 1010 or kind == 1011 or kind == 1012 or kind == 1013 or kind == 1014 or kind == 1015 or kind == 1016 or kind == 1017 or kind == 1018 or kind == 1019 or kind == 1020 or kind == 1021 or kind == 1022 or kind == 1023 or kind == 1024 or kind == 1025 or kind == 1026 or kind == 1027

pub fn build_graph_kind_valid(kind: i32) -> bool:
    build_graph_kind_is_standard(kind) or build_graph_kind_is_project(kind)

pub fn build_graph_kind_name(kind: i32) -> str:
    if kind == 0: return "executable"
    if kind == 1: return "library"
    if kind == 2: return "test"
    if kind == 3: return "object"
    if kind == 4: return "archive"
    if kind == 5: return "removed_generated_source"
    if kind == 6: return "removed_generated_binary"
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
    if kind == 18: return "copy_tree"
    if kind == 19: return "run_corpus_test"
    if kind == 20: return "promote_tree_if_verified"
    if kind == 21: return "clean"
    if kind == 22: return "copy_file"
    if kind == 23: return "action"
    if kind == 1000: return "removed_embedded_runtime_extract_test"
    if kind == 1001: return "removed_selfhost_noop_local_regression"
    if kind == 1002: return "removed_cli_selfhost_smoke_test"
    if kind == 1003: return "removed_generate_compiler_entrypoints"
    if kind == 1004: return "removed_with_compiler_build"
    if kind == 1005: return "removed_pcre2_run_test"
    if kind == 1006: return "removed_pcre2_generated_check"
    if kind == 1007: return "removed_pcre2_generated_promote"
    if kind == 1008: return "removed_pcre2_build"
    if kind == 1009: return "removed_cli_selfhost_one_liner_test"
    if kind == 1010: return "removed_cli_selfhost_object_symbol_test"
    if kind == 1011: return "removed_cli_selfhost_build_w_test"
    if kind == 1012: return "removed_generate_compat_runtime"
    if kind == 1013: return "removed_with_compiler_ir"
    if kind == 1014: return "removed_cli_selfhost_project_test"
    if kind == 1015: return "removed_cli_selfhost_edge_test"
    if kind == 1016: return "removed_cli_selfhost_pcre2_prep_test"
    if kind == 1017: return "removed_cli_selfhost_migrate_basic_test"
    if kind == 1018: return "removed_cli_selfhost_migrate_core_test"
    if kind == 1019: return "removed_selfhost_suite_test"
    if kind == 1020: return "removed_generate_llvm_link_metadata"
    if kind == 1021: return "removed_pcre2_reference_prepare"
    if kind == 1022: return "removed_pcre2_migrate"
    // 1023 was skipped when project kinds were first named; keep it reserved.
    if kind == 1023: return "removed_unused_1023"
    if kind == 1024: return "removed_seed_download"
    if kind == 1025: return "removed_emit_c_test"
    if kind == 1026: return "removed_emit_c_fixpoint"
    if kind == 1027: return "removed_emit_c_roundtrip"
    f"unknown({kind})"

pub fn build_graph_kind_implemented(kind: i32) -> bool:
    if build_graph_kind_is_standard(kind):
        return true
    if build_graph_kind_is_project(kind):
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
