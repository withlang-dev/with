extern fn with_embedded_std_source(path: str) -> str

fn EMBEDDED_STD_PREFIX -> str: "<embedded-std>/"

fn embedded_std_is_module_rel(rel_path: str) -> bool:
    rel_path.starts_with("std/")

fn embedded_std_source(rel_path: str) -> str:
    with_embedded_std_source(rel_path)

fn embedded_std_display_path(rel_path: str) -> str:
    EMBEDDED_STD_PREFIX() ++ rel_path

fn embedded_std_resolve_path(rel_path: str) -> str:
    if not embedded_std_is_module_rel(rel_path):
        return ""
    let source = embedded_std_source(rel_path)
    if source.len() == 0:
        return ""
    embedded_std_display_path(rel_path)

fn embedded_std_rel_path(path: str) -> str:
    let prefix = EMBEDDED_STD_PREFIX()
    if not path.starts_with(prefix):
        return ""
    path.slice(prefix.len(), path.len())
