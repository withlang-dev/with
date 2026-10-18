// pub_lint: `pub` that nothing outside the package uses (D100, #2211).
//
//   with run tools/pub_lint.w <root.w>            report
//   with run tools/pub_lint.w <root.w> --apply    remove the `pub` of each reported declaration
//
// D100 (§18.3): without `pub` a declaration is visible throughout its
// package; `pub` is what another package needs. Every `pub` written to
// satisfy the old per-file rule inside one package overstates the API.
// This asks the compiler, never the text: `with analyze <root> facts`
// gives every declaration with its module, every resolved call, method
// resolution and name reference (`reference` facts carry the referencing
// and the declaring package); a `pub` declaration of the root's package
// that no reference from ANOTHER package names is reported. A library
// package whose consumers are outside this compilation keeps its `pub`:
// run the lint from a program that uses it, or not at all.
//
// `pub` is read from the declaration's own text at the byte the fact names
// (the facts carry no pub flag yet), and `--apply` removes exactly that
// token (`pub ` at the declaration's start), a byte edit on the file.
use std.fs
use std.process
use std.os
use std.string.parse
use std.collections.HashMap

fn fail(msg: &str) -> Never:
    eprint("pub_lint: " ++ msg)
    exit_code(2)

type Decl { path: str, name: str, start: i64, kind: str }

fn all_facts(root: &str) -> List[str]:
    let out_path = "out/tmp/pub_lint_facts.txt"
    let compiler = if env("WITH").len() > 0: env("WITH") else: "with".to_owned()
    let argv: List[str] = [compiler, "analyze", root.to_owned(), "facts".to_owned()]
    let finished = run_to_files(&argv, out_path, out_path ++ ".stderr", 900000)
    if finished.code != 0: fail("`with analyze " ++ root ++ " facts` exited " ++ f"{finished.code}; see " ++ out_path ++ ".stderr")
    var rows: List[str] = List.new()
    for l in read_file(out_path).unwrap_or("").split("\n"):
        if l.starts_with("fact\t"): rows.push(l.to_owned())
    rows

fn column(row: &str, index: i32) -> str:
    let parts = row.split("\t")
    if index < parts.len(): parts[index].to_owned() else: "".to_owned()

// The package a module path belongs to, as Sema spells it when no project
// manifest names one: the std tier is one package, the program another.
fn package_of(path: &str) -> str:
    if path.starts_with("<embedded-std>/") or path.starts_with("lib/std/") or path.contains("/lib/std/"): "<std>".to_owned() else: "<program>".to_owned()

fn detail_field(detail: &str, key: &str) -> str:
    for part in detail.split(" "):
        if part.starts_with(key ++ "="): return part[key.len() + 1..part.len()].to_owned()
    "".to_owned()

let argv = args()
if argv.len() < 2: fail("usage: with run tools/pub_lint.w <root.w> [--apply]")
let root = argv[1].to_owned()
let apply = argv.len() > 2 and argv[2] == "--apply"
let _ = mkdir_p("out/tmp")

// Single-pass extraction over `with analyze <root> facts`: declarations and
// types of the root's package, plus references/calls/method-resolutions from
// another package.
var decls: List[Decl] = List.new()
var used_outside: HashMap[str, i32] = HashMap.new()
for row in all_facts(root):
    let stage = column(row, 1)
    let kind = column(row, 2)
    if stage == "ast" and kind == "declaration":
        let path = column(row, 18)
        if package_of(path) != "<program>" or path.starts_with("<c_import"): continue
        let name = column(row, 19)
        if name.contains("$in$"): continue
        decls.push(Decl { path, name, start: parse(column(row, 14)), kind: "fn" })
    else if stage == "sema" and kind == "type":
        let path = column(row, 18)
        if path.len() == 0 or package_of(path) != "<program>" or path.starts_with("<c_import"): continue
        let name = column(row, 19)
        if name.contains("$in$") or name.contains("[") or column(row, 14).len() == 0: continue
        decls.push(Decl { path, name, start: parse(column(row, 14)), kind: "type" })
    else if kind == "reference":
        let detail = column(row, 20)
        if detail_field(detail, "from-package") != detail_field(detail, "target-package"):
            used_outside.insert(column(row, 19), 1)
    else if kind == "call" or kind == "method-resolution":
        if package_of(column(row, 18)) != "<program>":
            used_outside.insert(column(row, 19), 1)

var reported = 0
var edits: HashMap[str, List[i64]] = HashMap.new()
for d in decls:
    let text = read_file(d.path).unwrap_or("")
    if text.len() == 0 or d.start < 0 or d.start + 4 > text.len(): continue
    if text[d.start..d.start + 4] != "pub ": continue
    if used_outside.contains(d.name): continue
    reported = reported + 1
    print(d.path ++ f":{d.start}: pub " ++ d.name ++ " is used by nothing outside its package (D100: pub is what another package needs)")
    if apply:
        var starts: List[i64] = match edits.get(d.path):
            Some(v) => v
            None => List.new()
        starts.push(d.start)
        edits.insert(d.path, starts)
if apply:
    for (path, starts) in edits:
        var text = read_file(path).unwrap_or("")
        var remaining = *starts
        // Highest offset first, so earlier offsets stay valid.
        while remaining.len() > 0:
            var best = 0
            for k in 1..remaining.len():
                if remaining[k] > remaining[best]: best = k
            let at: i64 = remaining[best]
            remaining.remove(best)
            if text[at..at + 4] == "pub ": text = text[0..at].to_owned() ++ text[at + 4..text.len()]
        if write_file(path, text) != 0: fail("could not write " ++ path)
        print("rewrote " ++ path)
print(f"pub_lint: {decls.len()} declarations in the program, {reported} pub used by nothing outside its package" ++ (if apply: " (removed)" else: ""))
if reported > 0 and not apply: exit_code(1)
