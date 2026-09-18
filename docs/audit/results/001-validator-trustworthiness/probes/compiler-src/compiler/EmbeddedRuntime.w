// D30 R2a: runtime sources embed in the compiler exactly like the stdlib
// (EmbeddedStdlib.w is the pattern). Modules resolve under the synthetic
// <embedded-rt>/ prefix, keyed by repo-relative path ("rt/rt_core.w").
// R2b consults these from the frontend when the runtime joins the unit.
use compiler.EmbeddedRuntimeData

pub fn EMBEDDED_RT_PREFIX -> str: "<embedded-rt>/"

pub fn embedded_rt_is_module_rel(rel_path: &str) -> bool:
    rel_path.starts_with("rt/")

pub fn embedded_rt_source(rel_path: &str) -> str:
    embedded_rt_source_data(rel_path)

pub fn embedded_rt_list_modules() -> str:
    embedded_rt_list_modules_data()

pub fn embedded_rt_display_path(rel_path: &str) -> str:
    EMBEDDED_RT_PREFIX() ++ rel_path

pub fn embedded_rt_resolve_path(rel_path: &str) -> str:
    if not embedded_rt_is_module_rel(rel_path):
        return ""
    let source = embedded_rt_source(rel_path)
    if source.len() == 0:
        return ""
    embedded_rt_display_path(rel_path)

pub fn embedded_rt_rel_path(path: &str) -> str:
    let prefix = EMBEDDED_RT_PREFIX()
    if not path.starts_with(prefix):
        return ""
    path.slice(prefix.len(), path.len())
