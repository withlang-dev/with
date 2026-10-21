// The compiler's embedded .wo bundles (docs/spec/toolchain/wo_bundles.md, decisions.md D38).
//
// Each bundle's object, manifest and interface are embedded as blobs by the
// embed_object_files generator (`with_embedded_wo_<name>_o_*`,
// `with_embedded_wo_<name>_manifest_*`, `with_embedded_wo_<name>_wi_*`), and
// the generated compiler.EmbeddedBundlesData (build/runtime.w, from the
// bundle list the build passes) names them and hands out their blob
// addresses. Compilation registers every present bundle's interface before
// the first import resolves (D39); the link stage (compiler.Link) selects a
// bundle on demand — an undefined symbol carrying one of the manifest's
// module prefixes — after checking the manifest's abi-sha against this
// compiler's own (compiler.AbiStamp). A named bundle whose blobs are empty
// is a slot this binary does not fill (stage1 is linked before the tree's
// bundle exists): it is not present, and nothing consults it.
use compiler.EmbeddedBundlesData
use TargetSpec
use rt.rt_core

fn embedded_bundle_count() -> i32:
    embedded_bundles_count_data()

fn embedded_bundle_name(index: i32) -> str:
    embedded_bundles_name_data(index)
// The target a slot's bundle was built for: "" is this compiler's own, a
// platform name (`wasm32`) is a second target this binary carries beside
// it (#2131). A bundle is consulted only for the target being compiled.
fn embedded_bundle_target(index: i32) -> str:
    embedded_bundles_target_data(index)
fn embedded_bundle_for_this_target(index: i32) -> bool:
    let target = embedded_bundle_target(index)
    if target.len() == 0: target_spec_is_native() else: target == target_spec_resolved_name()

// A str view over an embedded blob (no copy): the {ptr, len} pair written
// directly, the way the link stage views embedded runtime objects.
fn embedded_blob_view(start: i64, end: i64) -> str:
    let len = end - start
    if start == 0 or len <= 0:
        return ""
    var out: str = ""
    unsafe:
        let sp = &raw mut out as *mut u8
        *(sp as *mut u64) = start as u64
        *((sp + 8u64) as *mut i64) = len
    out

fn embedded_bundle_manifest_text(index: i32) -> str:
    embedded_blob_view(embedded_bundles_manifest_start_data(index), embedded_bundles_manifest_end_data(index))

fn embedded_bundle_interface_text(index: i32) -> str:
    embedded_blob_view(embedded_bundles_interface_start_data(index), embedded_bundles_interface_end_data(index))

// A named slot this binary fills: its manifest blob has content.
fn embedded_bundle_present(index: i32) -> bool:
    embedded_bundle_manifest_text(index).len() > 0

// The module link-name prefixes (`__with_mod_<hash>__`) a manifest lists —
// its `prefix <p> <path>` lines. Codegen emits declarations only for
// functions whose module carries one of these; the link stage selects the
// bundle when an undefined symbol does.
fn bundle_manifest_prefixes(manifest: &str) -> List[str]:
    let out: List[str] = List.new()
    var start: i64 = 0
    while start < manifest.len():
        var end = start
        while end < manifest.len() and manifest[end] != '\n':
            end = end + 1
        let line = manifest.slice(start, end)
        if line.starts_with("prefix "):
            let rest = line.slice(7, line.len())
            var sp: i64 = 0
            while sp < rest.len() and rest[sp] != ' ':
                sp = sp + 1
            if sp > 0:
                out.push(with_str_clone_ref(rest.slice(0, sp)))
        start = end + 1
    out

// The canonical module paths a manifest lists — the `<path>` of its
// `prefix <p> <path>` lines.
fn bundle_manifest_paths(manifest: &str) -> List[str]:
    let out: List[str] = List.new()
    var start: i64 = 0
    while start < manifest.len():
        var end = start
        while end < manifest.len() and manifest[end] != '\n':
            end = end + 1
        let line = manifest.slice(start, end)
        if line.starts_with("prefix "):
            let rest = line.slice(7, line.len())
            var sp: i64 = 0
            while sp < rest.len() and rest[sp] != ' ':
                sp = sp + 1
            if sp + 1 < rest.len():
                out.push(with_str_clone_ref(rest.slice(sp + 1, rest.len())))
        start = end + 1
    out

// Every prefix any embedded bundle for the active target provides.
fn embedded_bundle_prefixes() -> List[str]:
    let out: List[str] = List.new()
    for bi in 0..embedded_bundle_count():
        if not embedded_bundle_present(bi):
            continue
        if not embedded_bundle_for_this_target(bi):
            continue
        let prefixes = bundle_manifest_prefixes(embedded_bundle_manifest_text(bi))
        for pi in 0..prefixes.len():
            out.push(with_str_clone_ref(prefixes[pi]))
    out

// Blob address pairs; the link stage turns them into byte slices.
fn embedded_bundle_manifest_start(index: i32) -> i64:
    embedded_bundles_manifest_start_data(index)

fn embedded_bundle_manifest_end(index: i32) -> i64:
    embedded_bundles_manifest_end_data(index)

fn embedded_bundle_object_start(index: i32) -> i64:
    embedded_bundles_object_start_data(index)

fn embedded_bundle_object_end(index: i32) -> i64:
    embedded_bundles_object_end_data(index)

// ── Import contracts (durable .wo, D138) ───────────────────────────────
// A corpus bundle's manifest records every symbol its object references
// and does not define — `import\t<symbol>\t<rt|foreign>\t<contract>` — and
// the runtime bundle's records every runtime symbol it defines —
// `provides\t<symbol>\t<contract>` (the contract text:
// BundleInterfaceEmit.bundle_symbol_contract). The rows of one key, each
// without the key and its tab.
fn bundle_manifest_rows(manifest: &str, key: &str) -> List[str]:
    let out: List[str] = List.new()
    let want = key ++ "\t"
    var start: i64 = 0
    while start < manifest.len():
        var end = start
        while end < manifest.len() and manifest[end] != '\n':
            end = end + 1
        let line = manifest.slice(start, end)
        if line.starts_with(want):
            out.push(with_str_clone_ref(line.slice(want.len(), line.len())))
        start = end + 1
    out

// Field `index` of a tab-separated row ("" past the end).
fn bundle_row_field(row: &str, index: i32) -> str:
    var field = 0
    var start: i64 = 0
    while start <= row.len():
        var end = start
        while end < row.len() and row[end] != '\t':
            end = end + 1
        if field == index:
            return with_str_clone_ref(row.slice(start, end))
        field = field + 1
        start = end + 1
    ""

// The contract a `provides` row set declares for `symbol` ("" when none).
fn bundle_provided_contract(provides: &List[str], symbol: &str) -> str:
    for i in 0..provides.len():
        if bundle_row_field(provides[i], 0) == symbol:
            return bundle_row_field(provides[i], 1)
    ""

// The runtime bundle's manifest: its modules are the embedded runtime's.
fn bundle_manifest_is_runtime(manifest: &str) -> bool:
    let paths = bundle_manifest_paths(manifest)
    for pi in 0..paths.len():
        if paths[pi].starts_with("<embedded-rt>/"):
            return true
    false
