// BuildGraphTools -- typed host tool resolution for build graph nodes.

extern fn with_getenv_str(name: str) -> str

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
    BuildTool { name: "llvm-clang", executable: "clang", env_name: "" }
