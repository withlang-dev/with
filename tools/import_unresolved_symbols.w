// Import (and publish) the one owner of every name a build log reports as
// unresolved.
//
// Imports are not transitive (§18.2, #1708) and the compiler's own tree has
// no privacy waiver (§18.3, #1520), so a module that named another module's
// declaration through a third module's import now fails with
//   error: undefined variable                (the name is read at the caret)
//   error: unknown type 'X'
//   error: symbol 'X' is not visible from this module
// For each such name that exactly one module under the source roots declares
// at top level, the referencing module gets `use <owner>` in its header and
// the owner's declaration gets `pub ` when it lacks it. A name with no owner,
// several owners, or its own module as owner is reported and left alone: the
// log is then not a visibility problem and needs a human. The compiler's own
// fix-it — "requires an explicit import (§18.1); add: use M.n" — is applied
// verbatim. Nothing changes without --apply.
//
//   with run tools/import_unresolved_symbols.w [--apply] [--root src] out/battery.log
use std.fs
use std.process
use std.string.parse

fn is_name_char(c: i32) -> bool: is_alnum(c) or c == '_'

fn is_qualifier(word: &str) -> bool:
    word == "unsafe" or word == "extern" or word == "mut" or word == "move" or word == "comptime" or word == "async"

fn is_decl_keyword(word: &str) -> bool:
    word == "fn" or word == "type" or word == "enum" or word == "let" or word == "var" or word == "const" or word == "trait" or word == "error" or word == "global"

// The name a column-0 declaration line declares, "" when it declares none
// (or declares a method `fn T.m`, which names no module-level symbol).
fn declared_name(line: &str) -> str:
    if line.len() == 0 or line.starts_with(" ") or line.starts_with("\t"): return ""
    let body = if line.starts_with("pub "): line.slice(4, line.len()) else: line.clone()
    let words = body.split(" ")
    var i = 0
    while i < words.len() and is_qualifier(words.get(i)): i = i + 1
    if i >= words.len() or not is_decl_keyword(words.get(i)): return ""
    i = i + 1
    if i < words.len() and words.get(i) == "var": i = i + 1
    if i >= words.len(): return ""
    let word = words.get(i)
    var end = 0 as i64
    while end < word.len() and is_name_char(word[end]): end = end + 1
    if end == 0: return ""
    if end < word.len() and word[end] == '.': return ""
    word.slice(0, end)

fn quoted_after(line: &str, prefix: &str) -> str:
    let parts = line.split(prefix)
    if parts.len() < 2: return ""
    let rest = parts.get(1)
    let close = rest.find("'")
    if close < 0: return ""
    rest.slice(0, close)

fn vec_contains(v: &Vec[str], s: &str) -> bool:
    for i in 0..v.len():
        if v.get(i) == s: return true
    false

fn source_files(dir: &str) -> Vec[str]:
    var out: Vec[str] = Vec.new()
    for entry in list_files_text(dir).split("\n"):
        if entry.len() == 0 or entry == dir: continue
        if entry.ends_with(".w"): out.push(entry.clone())
        else if entry.find(".") < 0:
            for nested in source_files(entry): out.push(nested.clone())
    out

// `src/compiler/Link.w` → `compiler.Link`.
fn module_name(path: &str) -> str:
    var rel = path.clone()
    if rel.starts_with("src/"): rel = rel.slice(4, rel.len())
    if rel.ends_with(".w"): rel = rel.slice(0, rel.len() - 2)
    rel.replace("/", ".")

// The log names the generated entry copy; the source is src/main.w.
fn source_path(path: &str) -> str:
    if path.ends_with("out/gen/main.w"): "src/main.w" else: path.clone()

// The identifier starting at 1-based `col` of line `nr` of `path`.
fn ident_at(path: &str, nr: i32, col: i32) -> str:
    let text = read_file(path) ?? ""
    let lines = text.split("\n")
    if nr < 1 or nr > lines.len() as i32: return ""
    let line = lines.get(nr - 1)
    var start = (col - 1) as i64
    if start < 0 or start >= line.len(): return ""
    var end = start
    while end < line.len() and is_name_char(line[end]): end = end + 1
    line.slice(start, end)

// Offset just past the last `use` line of the leading header (comments,
// blank lines, `use`, `module`); the header's end when it has no `use`.
fn header_insert_offset(text: &str) -> i64:
    var last_use_end = -1 as i64
    var line_start = 0 as i64
    let n = text.len()
    while line_start < n:
        var line_end = line_start
        while line_end < n and text[line_end] != '\n': line_end = line_end + 1
        let line = text.slice(line_start, line_end)
        if line.starts_with("use ") or line.starts_with("module "):
            last_use_end = line_end + 1
        else if line.len() > 0 and not line.starts_with("//") and not line.starts_with("#!"):
            break
        line_start = line_end + 1
    if last_use_end >= 0: last_use_end else: line_start

let argv = args()
var apply = false
var log_path = ""
var roots: Vec[str] = Vec.new()
var ai = 1
while ai < argv.len():
    let a = argv.get(ai)
    if a == "--apply": apply = true
    else if a == "--root" and ai + 1 < argv.len():
        ai = ai + 1
        roots.push(argv.get(ai).clone())
    else: log_path = a.clone()
    ai = ai + 1
if log_path.len() == 0:
    eprint("usage: import_unresolved_symbols [--apply] [--root <dir>]... <build.log>")
    exit_code(2)
if roots.len() == 0: roots.push("src")

// Top-level declaration index: name, file, whether already `pub`.
var decl_names: Vec[str] = Vec.new()
var decl_paths: Vec[str] = Vec.new()
var decl_pub: Vec[bool] = Vec.new()
for root in roots:
    for path in source_files(root):
        for line in (read_file(path) ?? "").split("\n"):
            let name = declared_name(line)
            if name.len() > 0:
                decl_names.push(name)
                decl_paths.push(path.clone())
                decl_pub.push(line.starts_with("pub "))

// (file, use-line) imports and (owner, name) publications, deduplicated.
var import_files: Vec[str] = Vec.new()
var import_lines: Vec[str] = Vec.new()
var pub_owners: Vec[str] = Vec.new()
var pub_names: Vec[str] = Vec.new()
var reports: Vec[str] = Vec.new()
var seen_keys: Vec[str] = Vec.new()

let log_lines = (read_file(log_path) ?? "").split("\n")
var li = 0
while li < log_lines.len() as i32:
    let line = log_lines.get(li)
    li = li + 1
    if not line.starts_with("error:"): continue
    // The location is the next ` --> path:line:col`.
    var loc = ""
    if li < log_lines.len() as i32 and log_lines.get(li).starts_with(" --> "):
        loc = log_lines.get(li).slice(5, log_lines.get(li).len())
    if loc.len() == 0: continue
    let parts = loc.split(":")
    if parts.len() < 3: continue
    let file = source_path(parts.get(0))
    let hint = quoted_after(line, "; add: use ")
    if line.contains("requires an explicit import (§18.1); add: use "):
        let use_line = "use " ++ line.split("; add: use ").get(1).trim()
        let key = "use\t" ++ file ++ "\t" ++ use_line
        if not vec_contains(&seen_keys, key):
            seen_keys.push(key)
            import_files.push(file.clone())
            import_lines.push(use_line)
        continue
    var name = ""
    if line.ends_with("undefined variable"):
        name = ident_at(file, parse(parts.get(1)), parse(parts.get(2)))
    else if line.contains("unknown type '"):
        name = quoted_after(line, "unknown type '")
    else if line.contains("' is not visible from this module"):
        name = quoted_after(line, "symbol '")
    if name.len() == 0: continue
    var owner = ""
    var owner_pub = false
    var owners = 0
    for k in 0..decl_names.len():
        if decl_names.get(k) == name:
            if owner != decl_paths.get(k): owners = owners + 1
            owner = decl_paths.get(k).clone()
            owner_pub = decl_pub.get(k)
    if owners != 1 or owner == file:
        let why = if owners == 0: "no top-level owner" else: if owners > 1: "several owners" else: "declared in the referencing module"
        let rep = f"{file}:{parts.get(1)}: '{name}': {why}"
        if not vec_contains(&reports, rep): reports.push(rep)
        continue
    let use_line = "use " ++ module_name(owner)
    let ukey = "use\t" ++ file ++ "\t" ++ use_line
    if not vec_contains(&seen_keys, ukey):
        seen_keys.push(ukey)
        import_files.push(file.clone())
        import_lines.push(use_line)
    let pkey = "pub\t" ++ owner ++ "\t" ++ name
    if not owner_pub and not vec_contains(&seen_keys, pkey):
        seen_keys.push(pkey)
        pub_owners.push(owner.clone())
        pub_names.push(name.clone())

// Publish first (the owner may also gain an import below; both rewrite it).
var published = 0
var touched: Vec[str] = Vec.new()
for p in pub_owners:
    if not vec_contains(&touched, p): touched.push(p.clone())
for owner in touched:
    let text = read_file(owner) ?? ""
    var out = ""
    for line in text.split("\n"):
        var emitted: str = line.clone()
        let name = declared_name(line)
        if name.len() > 0 and not line.starts_with("pub "):
            for k in 0..pub_owners.len():
                if pub_owners.get(k) == owner and pub_names.get(k) == name:
                    emitted = "pub " ++ line
                    published = published + 1
                    print(f"{owner}: pub {name}")
        out = out ++ emitted ++ "\n"
    if text.ends_with("\n") and out.ends_with("\n\n"): out = out.slice(0, out.len() - 1)
    if apply and out != text:
        if write_file(owner, out) != 0:
            eprint("could not write " ++ owner)
            exit_code(1)

var imported = 0
var files: Vec[str] = Vec.new()
for f in import_files:
    if not vec_contains(&files, f): files.push(f.clone())
for file in files:
    let text = read_file(file) ?? ""
    var present: Vec[str] = Vec.new()
    for line in text.split("\n"):
        if line.starts_with("use "): present.push(line.trim().clone())
    var added = ""
    for k in 0..import_files.len():
        if import_files.get(k) == file and not vec_contains(&present, import_lines.get(k)):
            added = added ++ import_lines.get(k) ++ "\n"
            present.push(import_lines.get(k).clone())
            imported = imported + 1
            print(f"{file}: {import_lines.get(k)}")
    if added.len() == 0: continue
    let at = header_insert_offset(text)
    let out = text.slice(0, at) ++ added ++ text.slice(at, text.len())
    if apply:
        if write_file(file, out) != 0:
            eprint("could not write " ++ file)
            exit_code(1)
for rep in reports: eprint(rep)
let mode = if apply: "applied" else: "would apply"
print(f"{mode}: {imported} import(s), {published} publication(s); {reports.len()} name(s) left for a human")
if reports.len() > 0: exit_code(1)
