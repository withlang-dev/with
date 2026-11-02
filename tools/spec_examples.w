// spec_examples -- every fenced With example in the specification compiles
// (bridge-the-impl-gap.md, Law 10: the mission is tested, not described).
//
//   with run tools/spec_examples.w [--compiler PATH] [--list]
//
// Walks the normative chapters (docs/spec/*.md) and docs/spec/stdlib/*.md
// (the guides, toolchain and implementation notes are documentation, not
// promises), takes every ``` block whose
// first line is not a known non-With marker (`// not With`, `text`, `sh`,
// `c`, `json`, `toml`, `ebnf`, a grammar rule), writes it to
// out/spec-examples/<file>-<n>.w and runs `with check` on it. A block in
// test/conformance/spec-examples-open.txt (one `<file>:<n>` per line) is
// expected to FAIL (an example of a ruling not implemented yet, or a spec
// defect filed under #2955); one that passes is reported so its line can
// go. Exit 1 on any unexpected result; the lane reads that.
use std.fs
use std.process

let argv = args()
var compiler = "out/release/bin/with"
var list_only = false
for i in 1..argv.len():
    if argv[i] == "--compiler" and i + 1 < argv.len(): compiler = argv[i + 1]
    if argv[i] == "--list": list_only = true

fn is_with_block(info: str, first: str) -> bool:
    let tag = info.trim()
    if tag.len() > 0 and tag != "with" and tag != "w": return false
    let head = first.trim()
    if head.starts_with("// not With") or head.starts_with("// fragment") or head.starts_with("$ ") or head.starts_with("error:") or head.starts_with("warning:"): return false
    if head.contains(" := ") or head.starts_with("<") or head.starts_with("#include") or head.starts_with("{"): return false
    true

var open_set: HashMap[str, i32] = HashMap.new()
var unexpected_list: List[str] = List.new()
let open_list = read_file("test/conformance/spec-examples-open.txt")
if open_list.is_ok():
    for raw in open_list.unwrap().split("\n"):
        let l = raw.trim()
        if l.len() > 0 and not l.starts_with("#"):
            let k = l.split("\t")[0]
            if open_set.contains(k): unexpected_list.push(k ++ " is listed twice in test/conformance/spec-examples-open.txt")
            open_set.insert(k, 1)

var files: List[str] = List.new()
for f in list_files_text("docs/spec").split("\n"):
    // the chapters and stdlib/ only: the walk is recursive
    let rel = f.slice(10, f.len())
    if not f.ends_with(".md"): continue
    if rel.contains("/") and not rel.starts_with("stdlib/"): continue
    files.push(f)

var unexpected = unexpected_list
var checked = 0
var visited: HashMap[str, i32] = HashMap.new()
var open_still_failing = 0
for path in files:
    let text = read_file(path)
    if text.is_err(): continue
    var in_block = false
    var info = ""
    var block = ""
    var n = 0
    for line in text.unwrap().split("\n"):
        if not in_block:
            if line.starts_with("```"):
                in_block = true
                info = line.slice(3, line.len())
                block = ""
            continue
        if line.starts_with("```"):
            in_block = false
            n = n + 1
            let first_nl = block.find("\n")
            let first = if first_nl < 0: block else: block.slice(0, first_nl)
            if not is_with_block(info, first): continue
            let key = path ++ ":" ++ n.to_string()
            if list_only:
                print(key)
                continue
            let stem = path.replace("/", "_").replace(".md", "")
            let out_path = "out/spec-examples/" ++ stem ++ "-" ++ n.to_string() ++ ".w"
            assert(write_file(out_path, block) == 0)
            let r = run_to_files(&[compiler, "check", out_path], out_path ++ ".out", out_path ++ ".err", 120000)
            checked = checked + 1
            visited.insert(key, 1)
            let expected_open = open_set.contains(key)
            if r.code == 0 and expected_open:
                unexpected.push(key ++ " now compiles; delete its line from test/conformance/spec-examples-open.txt")
            else if r.code != 0 and not expected_open:
                let stderr = read_file(out_path ++ ".err").unwrap()
                let err_nl = stderr.find("\n")
                let first_err = if err_nl < 0: stderr else: stderr.slice(0, err_nl)
                unexpected.push(key ++ " does not compile: " ++ first_err)
            else if r.code != 0:
                open_still_failing = open_still_failing + 1
            continue
        block = block ++ line ++ "\n"
if list_only: exit_code(0)
for (k, _) in open_set:
    if not visited.contains(k): unexpected.push(k ++ " is listed in test/conformance/spec-examples-open.txt but no such block exists")
for u in unexpected: eprint("spec-examples: " ++ u)
print(f"spec-examples: {checked} examples checked, {open_still_failing} open as recorded, {unexpected.len()} unexpected")
if unexpected.len() > 0: exit_code(1)
