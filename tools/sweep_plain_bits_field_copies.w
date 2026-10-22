// sweep_plain_bits_field_copies.w — remove the annotation of `let i: isize =
// self.idx` where the compiler proves it only forced a copy: the field is
// plain bits of exactly that type, so under D144 the unannotated binding
// takes the value. Compiler-driven, never textual: the sites are Sema's own
// ceremony record (`with check ROOT --ceremony-census`, pattern
// `plain-bits-field-copy-annotation`, the type node's byte span); the
// annotation that widens or narrows (`let n: i64 = self.count` over an
// `i32`) is never marked, since the types differ.
//
//   with run tools/sweep_plain_bits_field_copies.w COMPILER ROOT.w [ROOT.w ...]
use std.fs
use std.process
use std.string

let argv = args()
if argv.len() < 3:
    eprint("usage: sweep_plain_bits_field_copies.w COMPILER ROOT.w [ROOT.w ...]")
    exit_code(2)
let compiler = argv[1]

// D112: a corpus directory (one holding a corpus.stamp) is generated code.
fn in_corpus(path: &str) -> bool:
    var dir: str = path
    while dir.contains("/"):
        dir = dir.slice(0, dir.rfind("/"))
        if file_exists(dir ++ "/corpus.stamp"): return true
    false

fn tree_path(path: &str) -> str:
    if path.starts_with("<embedded-std>/std/"): return "lib/std/" ++ path.slice("<embedded-std>/std/".len(), path.len())
    path

var site_paths = []
var site_starts = []
var site_ends = []
var skipped = []

for ri in 2..argv.len():
    let root = argv[ri]
    let done = run_to_files(&[compiler, "check", root, "--ceremony-census"], "out/sweep-bits.txt", "out/sweep-bits.err", 600000)
    if done.code != 0:
        eprint(f"sweep: `{compiler} check {root} --ceremony-census` failed (exit {done.code}); see out/sweep-bits.err")
        exit_code(1)
    for line in (read_file("out/sweep-bits.txt") ?? "").split("\n"):
        let cols = line.split("\t")
        if cols.len() < 5 or cols[0] != "plain-bits-field-copy-annotation": continue
        let path = tree_path(cols[1])
        if in_corpus(path):
            skipped.push(f"{path}:{cols[2]} (migrated corpus, D112)")
            continue
        let start = parse(cols[3])
        let end = parse(cols[4])
        if start < 0 or end <= start: continue
        var dup = false
        for i in 0..site_paths.len():
            if site_paths[i] == path and site_starts[i] == start: dup = true
        if dup: continue
        site_paths.push(path)
        site_starts.push(start)
        site_ends.push(end)

var files = []
for p in site_paths:
    if not files.contains(p): files.push(p)
var total = 0
for path in files:
    var starts = []
    var ends = []
    for i in 0..site_paths.len():
        if site_paths[i] == path:
            starts.push(site_starts[i])
            ends.push(site_ends[i])
    let text = read_file(path) ?? ""
    if text.len() == 0:
        skipped.push(f"{path} (unreadable)")
        continue
    var order = []
    for i in 0..starts.len(): order.push(i)
    for a in 0..order.len():
        for b in (a + 1)..order.len():
            if starts[order[b]] > starts[order[a]]:
                let t: isize = order[a]
                order[a] = order[b]
                order[b] = t
    var out = text
    var count = 0
    for oi in 0..order.len():
        let i = order[oi]
        let s = starts[i]
        let e = ends[i]
        // The annotation is `: T` — the span is `T`; the colon and the
        // blanks before it go with it.
        var colon = s - 1
        while colon >= 0 and out[colon] == ' ': colon -= 1
        if colon < 0 or out[colon] != ':':
            skipped.push(f"{path}:{s} (no `:` before the type span: {out.slice(s, e)})")
            continue
        var name_end = colon
        while name_end > 0 and out[name_end - 1] == ' ': name_end -= 1
        out = out.slice(0, name_end) ++ out.slice(e, out.len())
        count += 1
    if count > 0:
        if write_file(path, out) != 0:
            eprint(f"sweep: cannot write {path}")
            exit_code(1)
        print(f"{path}: {count} removed")
        total += count
print(f"removed {total} annotation(s) the compiler proved forced only a copy (D144)")
if skipped.len() > 0:
    print("left alone:")
    for s in skipped: print("  " ++ s)
