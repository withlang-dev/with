// BuildGraphTools -- the C compiler a build-graph node runs (#623: the
// host curl, tar, nm, ar, opt and dsymutil descriptors were dead and are
// gone; nothing of the toolchain runs a host tool, D171).

use rt.rt_core

type BuildTool {
    name: str,
    executable: str,
    env_name: str,
}

fn build_graph_tool_from_env(env_name: &str, fallback: &str) -> str:
    let value = with_getenv_str(env_name)
    if value.len() > 0:
        return value
    with_str_clone_ref(fallback)

fn build_graph_tool(name: &str, env_name: &str, fallback: &str) -> BuildTool:
    BuildTool {
        name: with_str_clone_ref(name),
        executable: build_graph_tool_from_env(env_name, fallback),
        env_name: with_str_clone_ref(env_name),
    }

// A C compile is this compiler's own clang (`with cc`, #1915: the build
// reads nothing of the host) unless $CC names another; "" means our own.
// The host `cc` was Apple's on macOS and nothing at all on Windows (#809).
fn build_graph_cc_tool() -> BuildTool:
    build_graph_tool("cc", "CC", "")
