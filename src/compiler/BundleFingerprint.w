// D39 bundle interfaces (docs/wo_bundles.md, decisions.md D39): the
// exported-declaration fingerprint.
//
// The bundle build proves an interface is exact, not merely parseable:
// Sema computes the exported-declaration model from the corpus source
// (`with build <root> --emit-obj --bundle-corpus … --bundle-fingerprint a`)
// and, in a second process, from the emitted .wi (`with check <bundle>.wi
// --bundle-corpus … --bundle-fingerprint b`), and the two hashes must be
// equal. The rows hold spellings and layout numbers only — never a TypeId,
// node id, decl index, file id or byte span, which differ between the two
// Semas — sorted bytewise so declaration order cannot matter. Out of
// process on purpose: the interface registry is a process global, and a
// second Sema in one process would share ids with the first.
use compiler.BundleInterfaces
use compiler.BundleInterfaceEmit
use TargetSpec

extern fn with_str_clone_ref(s: &str) -> str
extern fn with_str_cmp_ref(a: &str, b: &str) -> i32

fn bf_sorted_lines(lines: &Vec[str]) -> Vec[str]:
    var sorted: Vec[str] = Vec.new()
    for i in 0..lines.len() as i32:
        let item = lines.get(i as i64)
        var out: Vec[str] = Vec.new()
        var inserted = false
        for j in 0..sorted.len() as i32:
            let existing = sorted.get(j as i64)
            if not inserted and with_str_cmp_ref(item, existing) < 0:
                out.push(with_str_clone_ref(item))
                inserted = true
            out.push(with_str_clone_ref(existing))
        if not inserted:
            out.push(with_str_clone_ref(item))
        sorted = out
    sorted

// The canonical TSV: a header naming the format and target, then one row
// per corpus module (the set of bundle-provided modules is part of the
// contract) and every export's row(s), one per line, sorted.
pub fn bundle_fingerprint_text(model: &BundleInterfaceModel) -> str:
    var lines: Vec[str] = Vec.new()
    for mi in 0..model.modules.len() as i32:
        lines.push("module\t" ++ model.modules.get(mi as i64))
    for ei in 0..model.exports.len() as i32:
        let rows = model.exports.get(ei as i64).row
        var start: i64 = 0
        while start < rows.len():
            var end = start
            while end < rows.len() and rows.byte_at(end) != '\n':
                end = end + 1
            if end > start:
                lines.push(with_str_clone_ref(rows.slice(start, end)))
            start = end + 1
    let sorted = bf_sorted_lines(&lines)
    var out = "bundle-fingerprint\tv1\ttarget:" ++ target_spec_resolved_name() ++ "\tcorpus:" ++ model.corpus ++ "\n"
    for li in 0..sorted.len() as i32:
        out = out ++ sorted.get(li as i64) ++ "\n"
    out

pub fn bundle_fingerprint_sha(text: &str) -> str: bundle_text_sha256(text)
