// strip_census_sites -- apply a mechanical rewrite at the sites the ceremony
// census lists (`with run tools/ceremony_census.w --sites PATTERN`), so a
// Sema-backed pattern is removed from the tree by its facts, never by a
// regex (CLAUDE.md "Compiler-driven rewrites, not regex").
//
//   with run tools/strip_census_sites.w str-clone|ref-at-ref-param|str-view-copy-annotation|plain-bits-field-copy-annotation SITES_FILE
//
// Each sites line is `pattern<TAB>file<TAB>line<TAB>start<TAB>end`, the
// byte span of the recorded node. For `str-clone` the rewrite drops the
// trailing `.clone()`; for `ref-at-ref-param` it drops the leading `&`; for
// `str-view-copy-annotation` and `plain-bits-field-copy-annotation` the span
// is the `ann_type_node` of `let x: T = ...` and the rewrite drops `: T`
// (including spaces around `:`).
// `<embedded-std>/std/x.w` is `lib/std/x.w`.
use std.fs
use std.process
use std.string.parse

fn site_path(raw: &str) -> str:
    if raw.starts_with("<embedded-std>/std/"): "lib/std/" ++ raw.slice(19, raw.len()) else: raw.to_owned()

type Span { start: i64, end: i64 }

let argv = args()
if argv.len() < 3:
    eprint("usage: with run tools/strip_census_sites.w PATTERN SITES_FILE")
    exit_code(2)
let pattern = argv[1]
let is_type_ann = pattern == "str-view-copy-annotation" or pattern == "plain-bits-field-copy-annotation"
if pattern != "str-clone" and pattern != "ref-at-ref-param" and not is_type_ann:
    eprint(f"strip_census_sites: no rewrite for pattern '{pattern}' (str-clone, ref-at-ref-param, str-view-copy-annotation, or plain-bits-field-copy-annotation)")
    exit_code(2)
// `str-clone` drops the span's trailing `.clone()`; `ref-at-ref-param`
// drops the span's leading `&` (the compiler auto-references at a `&T`
// parameter, §3.8; `&&x` and `&raw` are left alone);
// `*-copy-annotation` drops `: T` spanning `start..end`.
let suffix = if pattern == "str-clone": ".clone()" else: ""
let prefix = if pattern == "ref-at-ref-param": "&" else: ""
// Sites per file, applied from the end so earlier offsets stay valid.
var by_file: HashMap[str, List[Span]] = HashMap.new()
let listing = read_file(argv[2]).expect("strip_census_sites: cannot read the sites file")
for line in listing.split("\n"):
    let cols = line.split("\t")
    if cols.len() < 5 or cols[0] != pattern: continue
    let path = site_path(cols[1])
    if path.starts_with("out/"): continue
    let start: i64 = parse(cols[3])
    let end: i64 = parse(cols[4])
    var bucket: List[Span] = by_file.remove(path) ?? List.new()
    bucket.push(Span { start, end })
    by_file.insert(path, bucket)
var files = 0
var sites = 0
var skipped = 0
for (path, spans) in by_file.into_iter():
    let Ok(loaded) = read_file(path) else:
        eprint(f"strip_census_sites: cannot read {path}")
        skipped += spans.len()
        continue
    var text = loaded
    // Insertion sort by start ascending.
    var sorted = spans
    for si in 1..sorted.len():
        let cur = sorted[si]
        var j = si
        while j > 0 and sorted[j - 1].start > cur.start:
            sorted[j] = sorted[j - 1]
            j -= 1
        sorted[j] = cur
    var i = sorted.len() - 1
    while i >= 0:
        let sp = sorted[i]
        i -= 1
        if suffix.len() > 0:
            let at = sp.end
            if at > text.len() or at < suffix.len() or text.slice(at - suffix.len(), at) != suffix:
                eprint(f"strip_census_sites: {path}: the span ending at byte {at} does not end in `.clone()`; left alone")
                skipped += 1
                continue
            text = text.slice(0, at - suffix.len()) ++ text.slice(at, text.len())
        else if is_type_ann:
            if sp.end > text.len() or sp.start < 1 or sp.end <= sp.start:
                eprint(f"strip_census_sites: {path}: invalid span {sp.start}..{sp.end}; left alone")
                skipped += 1
                continue
            var p = sp.start
            while p > 0 and (text[p - 1] == " "[0] or text[p - 1] == "\t"[0]):
                p -= 1
            if p == 0 or text[p - 1] != ":"[0]:
                eprint(f"strip_census_sites: {path}: no `:` before type annotation at byte {sp.start}; left alone")
                skipped += 1
                continue
            p -= 1
            while p > 0 and (text[p - 1] == " "[0] or text[p - 1] == "\t"[0]):
                p -= 1
            text = text.slice(0, p) ++ text.slice(sp.end, text.len())
        else:
            let at = sp.start
            let after = if at + 4 <= text.len(): text.slice(at, at + 4) else: ""
            if at + 1 > text.len() or text.slice(at, at + 1) != prefix or after.starts_with("&&") or after.starts_with("&raw"):
                eprint(f"strip_census_sites: {path}: the span at byte {at} does not start with a plain `&`; left alone")
                skipped += 1
                continue
            text = text.slice(0, at) ++ text.slice(at + 1, text.len())
        sites += 1
    write_file(path, text)
    files += 1
print(f"strip_census_sites: {pattern}: {sites} site(s) rewritten in {files} file(s), {skipped} skipped")
