use compiler.EmbeddedStdlibData
use compiler.BundleInterfaces
use rt.rt_core

fn EMBEDDED_STD_PREFIX -> str: "<embedded-std>/"

fn embedded_std_is_module_rel(rel_path: &str) -> bool:
    rel_path.starts_with("std/")

fn embedded_std_source(rel_path: &str) -> str:
    embedded_std_source_data(rel_path)

fn embedded_std_list_modules() -> str:
    embedded_std_list_modules_data()

fn embedded_std_display_path(rel_path: &str) -> str:
    EMBEDDED_STD_PREFIX() ++ rel_path

// The canonical `<embedded-std>/<rel>` path when the module is embedded or a
// bundle interface provides it (D39: consulted first — corpus sources are
// excluded from the embedded tree, their interfaces stand in).
fn embedded_std_resolve_path(rel_path: &str) -> str:
    if not embedded_std_is_module_rel(rel_path):
        return ""
    // A module is found as `name.with`, and as `name.w` while the
    // extension changes; `name.with` wins.
    if rel_path.ends_with(".w"):
        let found = embedded_std_resolve_path(rel_path ++ "ith")
        if found.len() > 0: return found
    let display = embedded_std_display_path(rel_path)
    if bundle_interface_text(display).len() > 0:
        return display
    let source = embedded_std_source(rel_path)
    if source.len() == 0:
        return ""
    display

fn embedded_std_rel_path(path: &str) -> str:
    let prefix = EMBEDDED_STD_PREFIX()
    if not path.starts_with(prefix):
        return ""
    path.slice(prefix.len(), path.len())
