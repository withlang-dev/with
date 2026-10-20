// D30 R2a: runtime sources embed in the compiler exactly like the stdlib
// (EmbeddedStdlib.w is the pattern). Modules resolve under the synthetic
// <embedded-rt>/ prefix, keyed by repo-relative path ("rt/rt_core.w").
// R2b consults these from the frontend when the runtime joins the unit.
use compiler.EmbeddedRuntimeData
use TargetSpec

fn EMBEDDED_RT_PREFIX -> str: "<embedded-rt>/"

fn embedded_rt_is_module_rel(rel_path: &str) -> bool:
    rel_path.starts_with("rt/")

fn embedded_rt_source(rel_path: &str) -> str:
    embedded_rt_source_data(rel_path)

fn embedded_rt_list_modules() -> str:
    embedded_rt_list_modules_data()

fn embedded_rt_display_path(rel_path: &str) -> str:
    EMBEDDED_RT_PREFIX() ++ rel_path

// The runtime's platform module for the active target (the host's when none
// is active), and the fiber core that goes with it: the one owner the
// in-unit parse (Frontend.parse_runtime_modules_frontend), the bundle root
// and the `rt.platform` / `rt.fiber_core` spellings read. D30 step 3: a
// standard-library module names a runtime seam by its role, never by the
// host it was compiled on.
fn embedded_rt_platform_file() -> str:
    var kind = target_spec_active_kind()
    if kind == 0:
        kind = target_spec_host_kind()
    if kind == 1: return "rt/linux_x86_64.w"
    if kind == 2: return "rt/linux_aarch64.w"
    if kind == 4: return "rt/darwin_aarch64.w"
    if kind == 5: return "rt/windows_x86_64.w"
    if kind == 6: return "rt/windows_aarch64.w"
    ""

fn embedded_rt_fiber_core_file() -> str:
    let platform = embedded_rt_platform_file()
    if platform.len() == 0:
        return ""
    if platform.starts_with("rt/windows"): "rt/fiber_core_windows.w" else: "rt/fiber_core_darwin.w"

// `rt/platform.w` and `rt/fiber_core.w` are the target's modules by role.
fn embedded_rt_real_path(rel_path: &str) -> str:
    if rel_path == "rt/platform.w": return embedded_rt_platform_file()
    if rel_path == "rt/fiber_core.w": return embedded_rt_fiber_core_file()
    rel_path ++ ""

fn embedded_rt_resolve_path(rel_path: &str) -> str:
    if not embedded_rt_is_module_rel(rel_path):
        return ""
    let real = embedded_rt_real_path(rel_path)
    if real.len() == 0:
        return ""
    let source = embedded_rt_source(real)
    if source.len() == 0:
        return ""
    embedded_rt_display_path(real)

fn embedded_rt_rel_path(path: &str) -> str:
    let prefix = EMBEDDED_RT_PREFIX()
    if not path.starts_with(prefix):
        return ""
    path.slice(prefix.len(), path.len())
