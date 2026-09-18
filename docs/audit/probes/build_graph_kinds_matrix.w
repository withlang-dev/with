extern fn with_sysinfo_os() -> str
extern fn with_sysinfo_arch() -> str

const BUILD_GRAPH_STANDARD_KIND_MIN: i32 = 0
const BUILD_GRAPH_STANDARD_KIND_MAX: i32 = 23
const BUILD_GRAPH_PROJECT_KIND_MIN: i32 = 1000
const BUILD_GRAPH_PROJECT_KIND_MAX: i32 = 1027
const BUILD_GRAPH_TARGET_MIN: i32 = 0
const BUILD_GRAPH_TARGET_MAX: i32 = 6

fn build_graph_kind_is_standard(kind: i32) -> bool:
    if kind >= BUILD_GRAPH_STANDARD_KIND_MIN and kind <= 4:
        return true
    kind >= 7 and kind <= BUILD_GRAPH_STANDARD_KIND_MAX

fn build_graph_kind_is_project(kind: i32) -> bool:
    false

fn build_graph_kind_removed(kind: i32) -> bool:
    kind == 5 or kind == 6 or kind == 1000 or kind == 1001 or kind == 1002 or kind == 1003 or kind == 1004 or kind == 1005 or kind == 1006 or kind == 1007 or kind == 1008 or kind == 1009 or kind == 1010 or kind == 1011 or kind == 1012 or kind == 1013 or kind == 1014 or kind == 1015 or kind == 1016 or kind == 1017 or kind == 1018 or kind == 1019 or kind == 1020 or kind == 1021 or kind == 1022 or kind == 1023 or kind == 1024 or kind == 1025 or kind == 1026 or kind == 1027

fn build_graph_kind_valid(kind: i32) -> bool:
    build_graph_kind_is_standard(kind) or build_graph_kind_is_project(kind)

fn build_graph_kind_name(kind: i32) -> str:
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
    if kind == 1023: return "removed_unused_1023"
    if kind == 1024: return "removed_seed_download"
    if kind == 1025: return "removed_emit_c_test"
    if kind == 1026: return "removed_emit_c_fixpoint"
    if kind == 1027: return "removed_emit_c_roundtrip"
    f"unknown({kind})"

fn build_graph_kind_implemented(kind: i32) -> bool:
    if build_graph_kind_is_standard(kind): return true
    if build_graph_kind_is_project(kind): return true
    false

fn build_graph_target_valid(kind: i32) -> bool:
    kind >= BUILD_GRAPH_TARGET_MIN and kind <= BUILD_GRAPH_TARGET_MAX

fn build_graph_target_name(kind: i32) -> str:
    if kind == 0: return "native"
    if kind == 1: return "linux_x86_64"
    if kind == 2: return "linux_aarch64"
    if kind == 3: return "darwin_x86_64"
    if kind == 4: return "darwin_aarch64"
    if kind == 5: return "windows_x86_64"
    if kind == 6: return "windows_aarch64"
    f"unknown({kind})"

fn build_graph_host_target_kind() -> i32:
    let os = with_sysinfo_os()
    let arch = with_sysinfo_arch()
    if os == "Macos":
        if arch == "aarch64": return 4
        if arch == "x86_64": return 3
    if os == "Linux":
        if arch == "aarch64": return 2
        if arch == "x86_64": return 1
    if os == "Windows":
        if arch == "aarch64": return 6
        if arch == "x86_64": return 5
    0

fn build_graph_target_is_host(kind: i32) -> bool:
    if kind == 0: return true
    kind == build_graph_host_target_kind()

fn main:
    for kind in 0..24:
        let expected = kind != 5 and kind != 6
        assert(build_graph_kind_valid(kind) == expected)
        assert(build_graph_kind_implemented(kind) == expected)
        assert(build_graph_kind_removed(kind) == not expected)
    for kind in 1000..1028:
        assert(build_graph_kind_removed(kind))
        assert(not build_graph_kind_valid(kind))
        assert(not build_graph_kind_implemented(kind))
    assert(not build_graph_kind_valid(-1))
    assert(not build_graph_kind_valid(24))
    assert(not build_graph_kind_removed(999))
    assert(not build_graph_kind_removed(1028))
    assert(build_graph_kind_name(0) == "executable")
    assert(build_graph_kind_name(1) == "library")
    assert(build_graph_kind_name(2) == "test")
    assert(build_graph_kind_name(3) == "object")
    assert(build_graph_kind_name(4) == "archive")
    assert(build_graph_kind_name(5) == "removed_generated_source")
    assert(build_graph_kind_name(6) == "removed_generated_binary")
    assert(build_graph_kind_name(7) == "command")
    assert(build_graph_kind_name(8) == "install")
    assert(build_graph_kind_name(9) == "group")
    assert(build_graph_kind_name(10) == "binary_compare")
    assert(build_graph_kind_name(11) == "fixpoint_compare")
    assert(build_graph_kind_name(12) == "compile_c_object")
    assert(build_graph_kind_name(13) == "compile_asm_object")
    assert(build_graph_kind_name(14) == "compile_llvm_ir_object")
    assert(build_graph_kind_name(15) == "create_static_archive")
    assert(build_graph_kind_name(16) == "generate_response_file")
    assert(build_graph_kind_name(17) == "embed_object_files")
    assert(build_graph_kind_name(18) == "copy_tree")
    assert(build_graph_kind_name(19) == "run_corpus_test")
    assert(build_graph_kind_name(20) == "promote_tree_if_verified")
    assert(build_graph_kind_name(21) == "clean")
    assert(build_graph_kind_name(22) == "copy_file")
    assert(build_graph_kind_name(23) == "action")
    assert(build_graph_kind_name(1000) == "removed_embedded_runtime_extract_test")
    assert(build_graph_kind_name(1001) == "removed_selfhost_noop_local_regression")
    assert(build_graph_kind_name(1002) == "removed_cli_selfhost_smoke_test")
    assert(build_graph_kind_name(1003) == "removed_generate_compiler_entrypoints")
    assert(build_graph_kind_name(1004) == "removed_with_compiler_build")
    assert(build_graph_kind_name(1005) == "removed_pcre2_run_test")
    assert(build_graph_kind_name(1006) == "removed_pcre2_generated_check")
    assert(build_graph_kind_name(1007) == "removed_pcre2_generated_promote")
    assert(build_graph_kind_name(1008) == "removed_pcre2_build")
    assert(build_graph_kind_name(1009) == "removed_cli_selfhost_one_liner_test")
    assert(build_graph_kind_name(1010) == "removed_cli_selfhost_object_symbol_test")
    assert(build_graph_kind_name(1011) == "removed_cli_selfhost_build_w_test")
    assert(build_graph_kind_name(1012) == "removed_generate_compat_runtime")
    assert(build_graph_kind_name(1013) == "removed_with_compiler_ir")
    assert(build_graph_kind_name(1014) == "removed_cli_selfhost_project_test")
    assert(build_graph_kind_name(1015) == "removed_cli_selfhost_edge_test")
    assert(build_graph_kind_name(1016) == "removed_cli_selfhost_pcre2_prep_test")
    assert(build_graph_kind_name(1017) == "removed_cli_selfhost_migrate_basic_test")
    assert(build_graph_kind_name(1018) == "removed_cli_selfhost_migrate_core_test")
    assert(build_graph_kind_name(1019) == "removed_selfhost_suite_test")
    assert(build_graph_kind_name(1020) == "removed_generate_llvm_link_metadata")
    assert(build_graph_kind_name(1021) == "removed_pcre2_reference_prepare")
    assert(build_graph_kind_name(1022) == "removed_pcre2_migrate")
    assert(build_graph_kind_name(1023) == "removed_unused_1023")
    assert(build_graph_kind_name(1024) == "removed_seed_download")
    assert(build_graph_kind_name(1025) == "removed_emit_c_test")
    assert(build_graph_kind_name(1026) == "removed_emit_c_fixpoint")
    assert(build_graph_kind_name(1027) == "removed_emit_c_roundtrip")
    assert(build_graph_kind_name(1028) == "unknown(1028)")
    for kind in 0..7: assert(build_graph_target_valid(kind))
    assert(not build_graph_target_valid(-1))
    assert(not build_graph_target_valid(7))
    assert(build_graph_target_name(0) == "native")
    assert(build_graph_target_name(1) == "linux_x86_64")
    assert(build_graph_target_name(2) == "linux_aarch64")
    assert(build_graph_target_name(3) == "darwin_x86_64")
    assert(build_graph_target_name(4) == "darwin_aarch64")
    assert(build_graph_target_name(5) == "windows_x86_64")
    assert(build_graph_target_name(6) == "windows_aarch64")
    assert(build_graph_target_name(7) == "unknown(7)")
    assert(with_sysinfo_os() == "Linux")
    assert(with_sysinfo_arch() == "x86_64")
    assert(build_graph_host_target_kind() == 1)
    assert(build_graph_target_is_host(0))
    assert(build_graph_target_is_host(1))
    assert(not build_graph_target_is_host(2))
    print("build-graph-kinds-matrix: ok")
