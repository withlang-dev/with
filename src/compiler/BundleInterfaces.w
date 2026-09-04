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
use std.crypto.sha256
extern fn with_str_clone_ref(s: &str) -> str

var g_bundle_interface_texts: HashMap[str, str] = HashMap.new()

// sha256 hex of a text — the manifest's `interface-sha` (the .wi bytes) and
// the fingerprint (the canonical declaration rows).
pub fn bundle_text_sha256(text: &str) -> str:
    var digest: [32]u8 = [0 as u8; 32]
    sha256_hash_str(text, &raw mut digest[0] as *mut u8)
    sha256_hex(&digest[0] as *const u8)

// `--bundle-corpus <rel>` names the module `<embedded-std>/<rel>.w` or the
// directory `<embedded-std>/<rel>/` — `std/re` is pcre2's corpus, `std/wi_demo`
// the one-module demo.
pub fn bundle_corpus_contains(corpus: &str, canonical_path: &str) -> bool:
    if corpus.len() == 0:
        return false
    let base = "<embedded-std>/" ++ corpus
    canonical_path == base ++ ".w" or canonical_path.starts_with(base ++ "/")

// `<embedded-std>/std/re/defs.w` → `std.re.defs`; "" for any other path.
pub fn bundle_module_dotted_name(canonical_path: &str) -> str:
    let prefix = "<embedded-std>/"
    if not canonical_path.starts_with(prefix) or not canonical_path.ends_with(".w"):
        return ""
    let rel = canonical_path.slice(prefix.len(), canonical_path.len() - 2)
    var out = ""
    for i in 0..rel.len():
        out = out ++ (if rel[i] == '/': "." else: rel.slice(i, i + 1))
    out

// The `module <path>` section paths of an interface file, in file order.
pub fn bundle_interface_section_paths(wi_text: &str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    var start: i64 = 0
    while start < wi_text.len():
        var end = start
        while end < wi_text.len() and wi_text[end] != '\n':
            end = end + 1
        let line = wi_text.slice(start, end)
        if line.starts_with("module "):
            out.push(bundle_interface_trim(line.slice(7, line.len())))
        start = end + 1
    out

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
    while a < b and (s[a] == ' ' or s[a] == '\t'):
        a = a + 1
    while b > a and (s[b - 1] == ' ' or s[b - 1] == '\t' or s[b - 1] == '\r'):
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
        while end < wi_text.len() and wi_text[end] != '\n':
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
