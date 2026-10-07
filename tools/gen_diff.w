// gen_diff: the generation differential (#2249, tool 5).
//
//   with run tools/gen_diff.w <compiler-a> <compiler-b> <file.w> [query]
//   with run tools/gen_diff.w out/bootstrap/bin/with-stage1 out/release/bin/with repro.w
//   with run tools/gen_diff.w out/bootstrap/bin/with-stage1 ~/.local/bin/with repro.w explain:modules
//
// Two compiler generations compiled from one tree must say the same thing
// about one program. This runs `<compiler> analyze <file> <query>` (default
// `facts`) under both, normalizes the ids that shift between builds (fact,
// node, symbol, signature and type ids are positions, not meaning), and
// prints the lines only one side produced. #2248 — a bare `Target` the
// release compiler refused and stage1 accepted — is one run of
// `explain:modules` (the loaded module sets differed) or `facts` (a
// declaration one side had and the other did not).
use std.fs
use std.process

fn fail(msg: &str) -> Never:
    eprint("gen_diff: " ++ msg)
    exit_code(2)

fn normalize(line: &str) -> str:
    var s = line.to_owned()
    // facts: id/parent/node/body/symbol/owner/index/type columns (2..11) are
    // positions; path, name and detail carry the meaning. A detail's
    // `key=NNN` ids are positions too.
    if s.starts_with("fact\t"):
        let parts = s.split("\t")
        if parts.len() >= 21:
            var out = "fact\t" ++ parts[1] ++ "\t" ++ parts[2]
            for i in 3..parts.len() as i32:
                out = out ++ "\t" ++ (if i >= 3 and i <= 13: "N".to_owned() else: parts[i].to_owned())
            s = out
    s = /\b(sig|mono|decl-node|name-decl-node|fn|node|owner|probe-sig|return|ty|type)=-?[0-9]+/g.replace(s, "$1=N")
    s = /\bsym[0-9]+/g.replace(s, "symN")
    s = /\bty[0-9]+/g.replace(s, "tyN")
    s = /\[[0-9]+\] /g.replace(s, "[N] ")
    // A std module read from the tree and its embedded copy are one module
    // (D38: the canonical spelling is the embedded one).
    s = /(^|[\t ])lib\/std\//g.replace(s, "$1<embedded-std>/std/")
    s

fn run_side(compiler: &str, file: &str, query: &str, label: &str) -> Vec[str]:
    let out_path = "out/tmp/gen_diff_" ++ label ++ ".txt"
    let argv: Vec[str] = [compiler.to_owned(), "analyze".to_owned(), file.to_owned(), query.to_owned()]
    let finished = run_to_files(&argv, out_path, out_path ++ ".stderr", 600000)
    if finished.code != 0:
        eprint(f"gen_diff: {label}: `" ++ compiler ++ "` exited {finished.code}; its stderr is in " ++ out_path ++ ".stderr (the diff below is over what it printed)")
    var lines: Vec[str] = Vec.new()
    for l in read_file(out_path).unwrap_or("").split("\n"):
        if l.len() > 0: lines.push(normalize(l))
    lines

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
if argv.len() < 4: fail("usage: with run tools/gen_diff.w <compiler-a> <compiler-b> <file.w> [query]")
let query = if argv.len() > 4: argv[4].to_owned() else: "select:kind=declaration".to_owned()
let _ = mkdir_p("out/tmp")
let a = run_side(argv[1], argv[3], query, "a")
let b = run_side(argv[2], argv[3], query, "b")
let only_a = only_in(&a, &b)
let only_b = only_in(&b, &a)
print(f"gen_diff {query}: {a.len()} lines from " ++ argv[1] ++ f", {b.len()} from " ++ argv[2])
for l in only_a: print("- " ++ l)
for l in only_b: print("+ " ++ l)
if only_a.len() == 0 and only_b.len() == 0:
    print("gen_diff: the two generations agree")
else:
    print(f"gen_diff: {only_a.len()} lines only in the first, {only_b.len()} only in the second")
    exit_code(1)
