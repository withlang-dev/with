// BuildGraphTools -- typed host tool resolution for build graph nodes.

extern fn with_getenv_str(name: str) -> str
extern fn with_sysinfo_os() -> str
extern fn with_sysinfo_arch() -> str

const BUILD_GRAPH_LLVM_VERSION: str = "22.1.6"
const BUILD_GRAPH_FALLBACK_LLVM_PREFIX: str = "/usr/local/llvm"

pub type BuildTool {
    name: str,
    executable: str,
    env_name: str,
}

pub fn build_graph_tool_from_env(env_name: str, fallback: str) -> str:
    let value = with_getenv_str(env_name)
    if value.len() > 0:
        return value
    fallback

pub fn build_graph_tool(name: str, env_name: str, fallback: str) -> BuildTool:
    BuildTool {
        name: name,
        executable: build_graph_tool_from_env(env_name, fallback),
        env_name: env_name,
    }

pub fn build_graph_cc_tool() -> BuildTool:
    build_graph_tool("cc", "CC", "cc")

pub fn build_graph_ar_tool() -> BuildTool:
    build_graph_tool("ar", "AR", "ar")

pub fn build_graph_nm_tool() -> BuildTool:
    build_graph_tool("nm", "NM", "nm")

pub fn build_graph_opt_tool() -> BuildTool:
    build_graph_tool("opt", "OPT", "opt")

pub fn build_graph_curl_tool() -> BuildTool:
    build_graph_tool("curl", "CURL", "curl")

pub fn build_graph_tar_tool() -> BuildTool:
    build_graph_tool("tar", "TAR", "tar")

pub fn build_graph_dsymutil_tool() -> BuildTool:
    build_graph_tool("dsymutil", "DSYMUTIL", "dsymutil")

pub fn build_graph_llvm_prefix() -> str:
    let prefix = with_getenv_str("LLVM_PREFIX")
    if prefix.len() > 0:
        return prefix
    let host_os = with_sysinfo_os()
    let host_arch = with_sysinfo_arch()
    if host_os == "Macos" and (host_arch == "armv8" or host_arch == "aarch64"):
        return ".deps/llvm-" ++ BUILD_GRAPH_LLVM_VERSION ++ "-darwin-arm64"
    if host_os == "Linux" and host_arch == "x86_64":
        return ".deps/llvm-" ++ BUILD_GRAPH_LLVM_VERSION ++ "-linux-x86_64"
    BUILD_GRAPH_FALLBACK_LLVM_PREFIX

pub fn build_graph_llvm_config_tool() -> BuildTool:
    let explicit = with_getenv_str("WITH_LLVM_CONFIG")
    if explicit.len() > 0:
        return BuildTool { name: "llvm-config", executable: explicit, env_name: "WITH_LLVM_CONFIG" }
    let legacy = with_getenv_str("LLVM_CONFIG")
    if legacy.len() > 0:
        return BuildTool { name: "llvm-config", executable: legacy, env_name: "LLVM_CONFIG" }
    BuildTool { name: "llvm-config", executable: build_graph_llvm_prefix() ++ "/bin/llvm-config", env_name: "LLVM_PREFIX" }

pub fn build_graph_llvm_clang_tool() -> BuildTool:
    let explicit = with_getenv_str("WITH_LLVM_CC")
    if explicit.len() > 0:
        return BuildTool { name: "llvm-clang", executable: explicit, env_name: "WITH_LLVM_CC" }
    let legacy = with_getenv_str("LLVM_CC")
    if legacy.len() > 0:
        return BuildTool { name: "llvm-clang", executable: legacy, env_name: "LLVM_CC" }
    let prefix = with_getenv_str("LLVM_PREFIX")
    if prefix.len() > 0:
        return BuildTool { name: "llvm-clang", executable: prefix ++ "/bin/clang", env_name: "LLVM_PREFIX" }
    BuildTool { name: "llvm-clang", executable: build_graph_llvm_prefix() ++ "/bin/clang", env_name: "LLVM_PREFIX" }
