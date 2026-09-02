// D39: the one lookup for a module's text (docs/wo_bundles.md). Every phase
// that reads an imported module goes through here — the resolver, the
// frontend's import merge, and diagnostic source mapping — so a
// bundle-provided module is its `.wi` section everywhere, with its canonical
// path unchanged. Order: bundle interface, embedded stdlib, embedded runtime,
// filesystem.
use compiler.BundleInterfaces
use compiler.EmbeddedStdlib
use compiler.EmbeddedRuntime
use compiler.Runtime

pub type ModuleSource {
    text: str,
    // Interface flavor: bodyless declarations parse in the Parser's
    // interface mode (Parser.enable_interface_mode).
    interface: bool,
}

pub fn module_source_read(path: &str) -> ModuleSource:
    let interface_text = bundle_interface_text(path)
    if interface_text.len() > 0:
        return ModuleSource { text: interface_text, interface: true }
    let embedded_rel = embedded_std_rel_path(path)
    if embedded_rel.len() > 0:
        return ModuleSource { text: embedded_std_source(embedded_rel), interface: false }
    let embedded_rt_rel = embedded_rt_rel_path(path)
    if embedded_rt_rel.len() > 0:
        return ModuleSource { text: embedded_rt_source(embedded_rt_rel), interface: false }
    ModuleSource { text: runtime_read_file(path), interface: path.ends_with(".wi") }
