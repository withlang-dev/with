// The compiler's embedded .wo bundles (docs/wo_bundles.md, decisions.md D38).
//
// Each bundle's object and manifest are embedded as blobs by the
// embed_object_files generator (`with_embedded_wo_<name>_o_*`,
// `with_embedded_wo_<name>_manifest_*`), and the generated
// compiler.EmbeddedBundlesData (build/runtime.w, from the bundle list the
// build passes) names them and hands out their blob addresses. The link
// stage (compiler.Link) selects a bundle on demand — an undefined symbol
// carrying one of the manifest's module prefixes — after checking the
// manifest's abi-sha against this compiler's own (compiler.AbiStamp).
// With no bundles the data module reports a count of zero.
use compiler.EmbeddedBundlesData

pub fn embedded_bundle_count() -> i32:
    embedded_bundles_count_data()

pub fn embedded_bundle_name(index: i32) -> str:
    embedded_bundles_name_data(index)

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

pub fn embedded_bundle_manifest_text(index: i32) -> str:
    embedded_blob_view(embedded_bundles_manifest_start_data(index), embedded_bundles_manifest_end_data(index))

// Every module link-name prefix (`__with_mod_<hash>__`) any embedded bundle
// provides — the `prefix <p> <path>` manifest lines across all bundles.
// Codegen emits declarations only for functions whose module carries one of
// these; the link stage selects the bundle when an undefined symbol does.
pub fn embedded_bundle_prefixes() -> Vec[str]:
    let out: Vec[str] = Vec.new()
    for bi in 0..embedded_bundle_count():
        let manifest = embedded_bundle_manifest_text(bi)
        var start: i64 = 0
        while start < manifest.len():
            var end = start
            while end < manifest.len() and manifest.byte_at(end) != '\n':
                end = end + 1
            let line = manifest.slice(start, end)
            if line.starts_with("prefix "):
                let rest = line.slice(7, line.len())
                var sp: i64 = 0
                while sp < rest.len() and rest.byte_at(sp) != ' ':
                    sp = sp + 1
                if sp > 0:
                    out.push(rest.slice(0, sp))
            start = end + 1
    out

// Blob address pairs; the link stage turns them into byte slices.
pub fn embedded_bundle_manifest_start(index: i32) -> i64:
    embedded_bundles_manifest_start_data(index)

pub fn embedded_bundle_manifest_end(index: i32) -> i64:
    embedded_bundles_manifest_end_data(index)

pub fn embedded_bundle_object_start(index: i32) -> i64:
    embedded_bundles_object_start_data(index)

pub fn embedded_bundle_object_end(index: i32) -> i64:
    embedded_bundles_object_end_data(index)
