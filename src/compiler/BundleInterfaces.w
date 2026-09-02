// D39 bundle interfaces (docs/wo_bundles.md, decisions.md D39): the `.wi`
// registry.
//
// A bundle's interface file holds one `module <canonical path>` line per
// bundle module, each followed by that module's declarations in interface
// flavor (bodyless functions, initializer-less storage). `--link-bundle
// <prefix>` registers `<prefix>.wi` here before the frontend resolves any
// import (Compilation.load_link_bundles); batch C3 registers the compiler's
// embedded bundle interfaces the same way. The resolver consults the registry
// BEFORE the embedded stdlib and the filesystem
// (EmbeddedStdlib.embedded_std_resolve_path, ModuleSource.module_source_read),
// so a bundle-provided module keeps its canonical
// `<embedded-std>/std/<corpus>/<name>.w` path and only its text changes.
use std.collections.HashMap
extern fn with_str_clone_ref(s: &str) -> str

var g_bundle_interface_texts: HashMap[str, str] = HashMap.new()

// The interface section registered for a canonical module path; "" when the
// path is not bundle-provided.
pub fn bundle_interface_text(path: &str) -> str:
    let found = g_bundle_interface_texts.get(path)
    if found.is_none():
        return ""
    with_str_clone_ref(found.unwrap())

fn bundle_interface_trim(s: &str) -> str:
    var a: i64 = 0
    var b = s.len()
    while a < b and (s.byte_at(a) == ' ' or s.byte_at(a) == '\t'):
        a = a + 1
    while b > a and (s.byte_at(b - 1) == ' ' or s.byte_at(b - 1) == '\t' or s.byte_at(b - 1) == '\r'):
        b = b - 1
    with_str_clone_ref(s.slice(a, b))

fn bundle_interfaces_register_section(path: &str, text: &str):
    g_bundle_interface_texts.insert(with_str_clone_ref(path), with_str_clone_ref(text))

// Register every `module <path>` section of an interface file. Returns the
// section count so a file with none is a loud error at the caller.
pub fn bundle_interfaces_register_wi(wi_text: &str) -> i32:
    var count = 0
    var section_path = ""
    var section_start: i64 = 0
    var start: i64 = 0
    while start < wi_text.len():
        var end = start
        while end < wi_text.len() and wi_text.byte_at(end) != '\n':
            end = end + 1
        let line = wi_text.slice(start, end)
        if line.starts_with("module "):
            if section_path.len() > 0:
                bundle_interfaces_register_section(section_path, wi_text.slice(section_start, start))
                count = count + 1
            section_path = bundle_interface_trim(line.slice(7, line.len()))
            section_start = end + 1
        start = end + 1
    if section_path.len() > 0:
        let tail = if section_start < wi_text.len(): wi_text.slice(section_start, wi_text.len()) else: ""
        bundle_interfaces_register_section(section_path, tail)
        count = count + 1
    count
