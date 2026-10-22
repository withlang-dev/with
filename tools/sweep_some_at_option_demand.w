// sweep_some_at_option_demand.w — remove `Some(x)` where the compiler proves
// D103 inserts it: an `Option[T]` is demanded and `x` has type `T` (not an
// Option). Compiler-driven, never textual: the sites are Sema's own
// ceremony record (`with check ROOT --ceremony-census`, pattern
// `some-at-option-demand`, with byte spans), so `return Some(None)` under an
// `Option[Option[T]]` is never touched — Sema does not mark it.
//
//   with run tools/sweep_some_at_option_demand.w COMPILER ROOT.w [ROOT.w ...]
//
// Prints one line per rewritten file with its count, and lists every site it
// left alone (a migrated corpus, D112; or a span that is not `Some(...)`).
use std.fs
use std.process
use std.string

let argv = args()
if argv.len() < 3:
    eprint("usage: sweep_some_at_option_demand.w COMPILER ROOT.w [ROOT.w ...]")
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

// The sites to remove, as parallel rows (path, start, end).
var site_paths = []
var site_starts = []
var site_ends = []
var skipped = []

for ri in 2..argv.len():
    let root = argv[ri]
    let done = run_to_files(&[compiler, "check", root, "--ceremony-census"], "out/sweep-some.txt", "out/sweep-some.err", 600000)
    if done.code != 0:
        eprint(f"sweep: `{compiler} check {root} --ceremony-census` failed (exit {done.code}); see out/sweep-some.err")
        exit_code(1)
    for line in (read_file("out/sweep-some.txt") ?? "").split("\n"):
        let cols = line.split("\t")
        if cols.len() < 5 or cols[0] != "some-at-option-demand": continue
        let path = tree_path(cols[1])
        if in_corpus(path):
            skipped.push(f"{path}:{cols[2]} (migrated corpus, D112)")
            continue
        let start = parse(cols[3])
        let end = parse(cols[4])
        if start < 0 or end <= start: continue
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
    // Edits from the end of the file backwards, so earlier offsets hold.
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
    var last_start = out.len() + 1
    for oi in 0..order.len():
        let i = order[oi]
        let s = starts[i]
        let e = ends[i]
        if e > last_start: continue   // nested inside a site already rewritten
        let span = out.slice(s, e)
        if not span.starts_with("Some(") or not span.ends_with(")"):
            skipped.push(f"{path}:{s} (span is not `Some(...)`: {span})")
            continue
        let inner = span.slice(5, span.len() - 1)
        out = out.slice(0, s) ++ inner ++ out.slice(e, out.len())
        last_start = s
        count += 1
    if count > 0:
        if write_file(path, out) != 0:
            eprint(f"sweep: cannot write {path}")
            exit_code(1)
        print(f"{path}: {count} removed")
        total += count
print(f"removed {total} Some(...) the compiler proved redundant (D103)")
if skipped.len() > 0:
    print("left alone:")
    for s in skipped: print("  " ++ s)
