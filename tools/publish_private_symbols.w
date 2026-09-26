// Declare `pub` the top-level symbols a compiler build reports as private.
//
// Sema (§18.3) owns the verdict: a saved build/check log names every
// cross-module reference of a private declaration as
//   error: symbol 'X' is private to module 'src/Y.w'
// or, when the private declaration's module is not on the current module's
// import path,
//   error: symbol 'X' is not visible from this module
// and every published signature that still names a private type as
//   error: pub fn 'f' names private type 'X' in its signature; ... (§18.1)
// This tool collects those (module, symbol) pairs and prefixes `pub ` to the
// one top-level declaration of each symbol in its owning module; a symbol
// reported without its module is looked up across the source roots. It never
// touches a declaration that is already `pub`, and it changes nothing without
// `--apply`. It was written for #1520 (module privacy no longer waived under
// `src/`), whose fallout only shows when stage1 compiles stage2.
//
//   with run tools/publish_private_symbols.w [--apply] [--root src] out/battery.log
use std.fs
use std.process

// A `.` continues a name too: `fn Type.method` declares the method, not `Type`.
fn is_ident_char(c: i32) -> bool: is_alnum(c) or c == '_' or c == '.'

// The quoted operand after `prefix`, "" when the line has no such operand.
fn quoted_after(line: &str, prefix: &str) -> str:
    let parts = line.split(prefix)
    if parts.len() < 2: return ""
    let rest = parts.get(1)
    let close = rest.find("'")
    if close < 0: return ""
    rest.slice(0, close)

fn is_qualifier(word: &str) -> bool:
    word == "unsafe" or word == "extern" or word == "mut" or word == "move" or word == "comptime" or word == "async"

fn is_decl_keyword(word: &str) -> bool:
    word == "fn" or word == "type" or word == "enum" or word == "let" or word == "var" or word == "const" or word == "trait" or word == "error"

// Whether `line` is the top-level declaration of `sym` (column 0, no `pub`).
fn declares(line: &str, sym: &str) -> bool:
    if line.len() == 0 or line.starts_with(" ") or line.starts_with("\t") or line.starts_with("pub "): return false
    let words = line.split(" ")
    var i = 0
    while i < words.len() and is_qualifier(words.get(i)): i = i + 1
    if i >= words.len() or not is_decl_keyword(words.get(i)): return false
    i = i + 1
    if i >= words.len(): return false
    let name_word = words.get(i)
    if not name_word.starts_with(sym): return false
    name_word.len() == sym.len() or not is_ident_char(name_word[sym.len()])

fn vec_contains(v: &Vec[str], s: &str) -> bool:
    for i in 0..v.len():
        if v.get(i) == s: return true
    false

// Every `.w` file under `dir`, recursively. (A plain file lists as itself,
// so an extensionless file such as `src/version` is a leaf, not a directory.)
fn source_files(dir: &str) -> Vec[str]:
    var out: Vec[str] = Vec.new()
    for entry in list_files_text(dir).split("\n"):
        if entry.len() == 0 or entry == dir: continue
        if entry.ends_with(".w"): out.push(entry.clone())
        else if entry.find(".") < 0:
            for nested in source_files(entry): out.push(nested.clone())
    out

// The module (under `roots`) whose top level declares `sym`; "" when none or
// more than one does.
fn owning_module(sym: &str, roots: &Vec[str]) -> str:
    var found = ""
    var count = 0
    for root in roots:
        for path in source_files(root):
            let text = read_file(path) ?? ""
            for line in text.split("\n"):
                if declares(line, sym):
                    found = path.clone()
                    count = count + 1
    if count == 1: found else: ""

let argv = args()
var apply = false
var log_path = ""
var roots: Vec[str] = Vec.new()
var i = 1
while i < argv.len():
    let a = argv.get(i)
    if a == "--apply": apply = true
    else if a == "--root" and i + 1 < argv.len():
        i = i + 1
        roots.push(argv.get(i).clone())
    else: log_path = a.clone()
    i = i + 1
if log_path.len() == 0:
    eprint("usage: publish_private_symbols [--apply] [--root <dir>]... <build.log>")
    exit_code(2)
if roots.len() == 0: roots.push("src")

// (module, symbol) pairs, deduplicated, in first-seen order.
var pair_owners: Vec[str] = Vec.new()
var pair_symbols: Vec[str] = Vec.new()
var unresolved: Vec[str] = Vec.new()
let log = read_file(log_path) ?? ""
for line in log.split("\n"):
    if not line.starts_with("error:"): continue
    var sym = quoted_after(line, "symbol '")
    if sym.len() == 0: sym = quoted_after(line, "names private type '")
    if sym.len() == 0: continue
    var owner = ""
    if line.contains("' is private to module '"):
        owner = quoted_after(line, "is private to module '")
    else if line.contains("' is not visible from this module") or line.contains("' in its signature; a public signature names only public types"):
        owner = owning_module(sym, &roots)
        if owner.len() == 0:
            if not vec_contains(&unresolved, sym): unresolved.push(sym.clone())
            continue
    else:
        continue
    var seen = false
    for k in 0..pair_owners.len():
        if pair_owners.get(k) == owner and pair_symbols.get(k) == sym: seen = true
    if not seen:
        pair_owners.push(owner)
        pair_symbols.push(sym)

// Distinct modules, then one rewrite pass per module.
var owners: Vec[str] = Vec.new()
for m in pair_owners:
    if not vec_contains(&owners, m): owners.push(m.clone())

var published = 0
var missing = 0
for owner in owners:
    var wanted: Vec[str] = Vec.new()
    for k in 0..pair_owners.len():
        if pair_owners.get(k) == owner: wanted.push(pair_symbols.get(k).clone())
    let text = match read_file(owner):
        Ok(t) => t
        Err(e) =>
            eprint(f"{owner}: {e.message()}")
            exit_code(1)
    var out = ""
    var done: Vec[str] = Vec.new()
    var nr = 0
    for line in text.split("\n"):
        nr = nr + 1
        var emitted: str = line.clone()
        for sym in wanted:
            if declares(line, sym):
                if vec_contains(&done, sym):
                    eprint(f"{owner}:{nr}: second top-level declaration of '{sym}'")
                    exit_code(1)
                emitted = "pub " ++ line
                done.push(sym.clone())
                published = published + 1
                print(f"{owner}:{nr}: pub {sym}")
        out = out ++ emitted ++ "\n"
    if text.ends_with("\n") and out.ends_with("\n\n"): out = out.slice(0, out.len() - 1)
    for sym in wanted:
        if not vec_contains(&done, sym):
            eprint(f"{owner}: no top-level declaration of '{sym}' (already pub, or not a top-level fn/type/enum/let/var/const)")
            missing = missing + 1
    if apply and out != text:
        if write_file(owner, out) != 0:
            eprint("could not write " ++ owner)
            exit_code(1)
for sym in unresolved:
    eprint(f"'{sym}': not visible, and no single top-level declaration under the source roots")
let mode = if apply: "published" else: "would publish"
print(f"{mode} {published} symbol(s) in {owners.len()} module(s); {missing} missing, {unresolved.len()} unresolved")
if missing > 0 or unresolved.len() > 0: exit_code(1)
