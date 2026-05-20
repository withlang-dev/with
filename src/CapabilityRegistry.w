// CapabilityRegistry -- shared identity for compiler-minted tool capabilities.

enum CapabilityKind: i32:
    CK_NONE = 0
    CK_BUILD_CTX = 1
    CK_BUILD_PROJECT_INFO = 2
    CK_BUILD_DIAGNOSTICS = 3
    CK_BUILD_SOURCE_EMITTER = 4
    CK_BUILD_TOOL_FS = 5
    CK_BUILD_PROCESS_RUNNER = 6
    CK_BUILD_ACTION_CTX = 7
    CK_COMPILER_DIAGNOSTICS = 8
    CK_COMPILER_SOURCE_EMITTER = 9

fn capability_registry_is_std_build_path(path: str) -> bool:
    path == "<embedded-std>/std/build.w" or path == "lib/std/build.w" or path.ends_with("/lib/std/build.w")

fn capability_registry_is_std_compiler_path(path: str) -> bool:
    path == "<embedded-std>/std/compiler.w" or path == "lib/std/compiler.w" or path.ends_with("/lib/std/compiler.w")

fn capability_registry_lookup_std_build(name: str) -> i32:
    if name == "BuildCtx": return CapabilityKind.CK_BUILD_CTX
    if name == "ProjectInfo": return CapabilityKind.CK_BUILD_PROJECT_INFO
    if name == "Diagnostics": return CapabilityKind.CK_BUILD_DIAGNOSTICS
    if name == "SourceEmitter": return CapabilityKind.CK_BUILD_SOURCE_EMITTER
    if name == "ToolFs": return CapabilityKind.CK_BUILD_TOOL_FS
    if name == "ProcessRunner": return CapabilityKind.CK_BUILD_PROCESS_RUNNER
    if name == "ActionCtx": return CapabilityKind.CK_BUILD_ACTION_CTX
    CapabilityKind.CK_NONE

fn capability_registry_lookup_std_compiler(name: str) -> i32:
    if name == "Diagnostics": return CapabilityKind.CK_COMPILER_DIAGNOSTICS
    if name == "SourceEmitter": return CapabilityKind.CK_COMPILER_SOURCE_EMITTER
    CapabilityKind.CK_NONE

fn capability_registry_lookup(module_path: str, type_name: str) -> i32:
    if capability_registry_is_std_build_path(module_path):
        return capability_registry_lookup_std_build(type_name)
    if capability_registry_is_std_compiler_path(module_path):
        return capability_registry_lookup_std_compiler(type_name)
    CapabilityKind.CK_NONE

fn capability_registry_is_capability(kind: i32) -> bool:
    kind != CapabilityKind.CK_NONE

fn capability_registry_kind_name(kind: i32) -> str:
    if kind == CapabilityKind.CK_BUILD_CTX: return "std.build.BuildCtx"
    if kind == CapabilityKind.CK_BUILD_PROJECT_INFO: return "std.build.ProjectInfo"
    if kind == CapabilityKind.CK_BUILD_DIAGNOSTICS: return "std.build.Diagnostics"
    if kind == CapabilityKind.CK_BUILD_SOURCE_EMITTER: return "std.build.SourceEmitter"
    if kind == CapabilityKind.CK_BUILD_TOOL_FS: return "std.build.ToolFs"
    if kind == CapabilityKind.CK_BUILD_PROCESS_RUNNER: return "std.build.ProcessRunner"
    if kind == CapabilityKind.CK_BUILD_ACTION_CTX: return "std.build.ActionCtx"
    if kind == CapabilityKind.CK_COMPILER_DIAGNOSTICS: return "std.compiler.Diagnostics"
    if kind == CapabilityKind.CK_COMPILER_SOURCE_EMITTER: return "std.compiler.SourceEmitter"
    "none"

fn capability_registry_compiler_hook_param_supported(module_path: str, type_name: str) -> bool:
    if not capability_registry_is_std_compiler_path(module_path):
        return false
    type_name == "ProjectInfo" or capability_registry_is_capability(capability_registry_lookup_std_compiler(type_name))
