// migrate_diff: the migration differential (#2230, part 2, v1).
//
//   with run tools/migrate_diff.w <old-dir> <new-dir> <main.w> <lib-subdir>
//   with run tools/migrate_diff.w lib/std/re out/pcre2_migrated pcre2test.w re
//
// Two migrations of the same C differ by the migrator's rewrites; this
// names every function whose lowered MIR differs between them, so "which of
// N rewrites changed behavior" is answered from the compiler's facts, never
// by rebuilding bundles file by file. Each side is laid out as
// `lib/std/<lib-subdir>/` under a scratch root (the cohesive layout the
// corpus check uses, so `use std.<subdir>.X` resolves), `<main.w>` is
// checked with `--dump-mir`, and the dump is split per function by name.
// Symbol ids (`symN`) are normalized — they shift with declaration order —
// and type ids are kept: a `ty3` that became `ty4` is a real difference.
// Then, per function present on both sides with a differing body, the
// lines present on one side only; functions on one side only are listed.
use std.fs
use std.process

fn fail(msg: &str) -> Never:
    eprint("migrate_diff: " ++ msg)
    exit_code(2)

fn read_or_fail(path: &str) -> str:
    match read_file(path):
        Ok(text) => text
        Err(e) => fail(path ++ ": " ++ e.message())

fn normalize(line: &str) -> str:
    // Ids are positions, not meaning: `sym1234` is declaration order, `_39`
    // and `bb7` renumber when one temporary or block comes or goes, `ty1931`
    // shifts when the type table gains an entry. Without the ids, what is
    // left is the statement itself — a call, a cast, an aggregate, a drop.
    if line.contains("locals truncated (") or line.contains("blocks truncated ("): return ""
    var out = /sym[0-9]+/g.replace(line, "sym")
    out = /\bbb[0-9]+/g.replace(out, "bb")
    out = /\bty[0-9]+/g.replace(out, "ty")
    out = /\.f[0-9]+/g.replace(out, ".f")
    /_[0-9]+/g.replace(out, "_")

// name → normalized body lines, from one `--dump-mir` text, in name order.
fn split_bodies(dump: &str) -> BTreeMap[str, Vec[str]]:
    var out: BTreeMap[str, Vec[str]] = BTreeMap.new()
    var name = ""
    var body: Vec[str] = Vec.new()
    for line in dump.split("\n"):
        if line.starts_with("fn sym") and line.ends_with(") {"):
            if name.len() > 0: out.insert(name.clone(), move body)
            body = Vec.new()
            let open = line.find("(")
            name = line[open + 1..line.len() - 3].to_owned()
        else if name.len() > 0:
            if line == "}":
                out.insert(name.clone(), move body)
                body = Vec.new()
                name = ""
            else:
                body.push(normalize(line))
    if name.len() > 0: out.insert(name, move body)
    out

fn dump_side(label: &str, src_dir: &str, main: &str, sub: &str) -> str:
    let root = "out/tmp/migrate-diff/" ++ label
    let lib_dir = root ++ "/lib/std/" ++ sub
    let _ = remove_tree(root)
    if mkdir_p(lib_dir) != 0: fail("could not create " ++ lib_dir)
    for entry in list_files_text(src_dir).split("\n"):
        if not entry.ends_with(".w"): continue
        let parts = entry.split("/")
        let name = parts[parts.len() as i32 - 1].to_owned()
        let text = read_or_fail(src_dir ++ "/" ++ name)
        if write_file(lib_dir ++ "/" ++ name, text) != 0: fail("could not copy " ++ name)
    // The corpus on its source and without the prelude, as its bundle
    // builds: with the embedded interface answering `use std.<sub>.X` the
    // dump holds no corpus body at all, and with the prelude on its
    // std.regex reaches the checkout's lib/std/re beside this tree (refused:
    // one std module, one source).
    let argv: Vec[str] = ["with", "check", "lib/std/" ++ sub ++ "/" ++ main, "--dump-mir", "--bundle-corpus", "std/" ++ sub, "--no-prelude"]
    let out_path = root ++ "/mir.txt"
    let finished = run_to_files_in(root, &argv, out_path, root ++ "/mir.stderr")
    if finished.code != 0:
        fail(label ++ f": check --dump-mir exited {finished.code}; see " ++ root ++ "/mir.stderr")
    read_or_fail(out_path)

// The lines of `a` not in `b` (as a multiset), in order.
fn only_in(a: &Vec[str], b: &Vec[str]) -> Vec[str]:
    var counts: HashMap[str, i32] = HashMap.new()
    for l in b: counts.insert(l.clone(), (counts.get(l) ?? 0) + 1)
    var out: Vec[str] = Vec.new()
    for l in a:
        let n = counts.get(l) ?? 0
        if n > 0: counts.insert(l.clone(), n - 1)
        else: out.push(l.clone())
    out

let argv = args()
if argv.len() != 5: fail("usage: with run tools/migrate_diff.w <old-dir> <new-dir> <main.w> <lib-subdir>")
let old_bodies = split_bodies(dump_side("old", argv[1], argv[3], argv[4]))
let new_bodies = split_bodies(dump_side("new", argv[2], argv[3], argv[4]))
var differing = 0
for name in old_bodies.keys():
    if not new_bodies.contains(name):
        print(f"- {name}: only in old")
        differing += 1
        continue
    let a = old_bodies.get(name).unwrap()
    let b = new_bodies.get(name).unwrap()
    let removed = only_in(a, b)
    let added = only_in(b, a)
    if removed.len() == 0 and added.len() == 0: continue
    differing += 1
    print(f"~ {name}: MIR differs (-{removed.len()} +{added.len()} lines)")
    var shown = 0
    for l in removed:
        if shown >= 8: break
        print("    - " ++ l.trim())
        shown += 1
    shown = 0
    for l in added:
        if shown >= 8: break
        print("    + " ++ l.trim())
        shown += 1
for name in new_bodies.keys():
    if not old_bodies.contains(name):
        print(f"+ {name}: only in new")
        differing += 1
print(f"migrate_diff: {old_bodies.len()} functions old, {new_bodies.len()} new, {differing} differ")
if differing > 0: exit_code(1)
