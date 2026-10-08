// ceremony_census -- count the known ceremony patterns across the tree
// (CLAUDE.md "Ceremony is a design defect, not a user error").
//
// Lexical patterns are counted from the tokens of every tracked .w file
// under src/, lib/, tools/, build/, build.w and examples/ (test/ fixtures
// spell these forms on purpose and are not counted):
//   clone-call       `.clone()`
//   len-cast         `.len() as`
//   let-underscore   `let _ =`
//   move-arg         `move x` (not `move fn` / `move self`)
//   copy-arg         `copy x`
// Typed patterns come from one compilation of src/main.w, which covers the
// compiler and lib/std (`with check --ceremony-census`):
//   str-clone              `.clone()` on a str
//   ref-at-ref-param       an explicit `&x` at a `&T` parameter
//   some-at-option-demand  `Some(x)` where an Option is demanded
//
// The record is build/ceremony-census.tsv. A count above the record fails;
// a count below it passes (lower the record with --write to keep it tight).
//
//   with run tools/ceremony_census.w                   # check against the record
//   with run tools/ceremony_census.w --write           # rewrite the record
//   with run tools/ceremony_census.w --sites PATTERN   # list one typed pattern's sites
//   --compiler PATH                                    # default out/release/bin/with

use std.fs
use std.process
use std.string
use Lexer
use Token

let RECORD = "build/ceremony-census.tsv"

fn area_of(path: &str):
    if path.starts_with("<embedded-std>/"): "lib"
    else if path == "build.w": "build"
    else: path.slice(0, path.find("/"))

fn counted(path: &str) -> bool:
    path.ends_with(".w") and (path == "build.w" or path.starts_with("src/") or path.starts_with("lib/") or path.starts_with("tools/") or path.starts_with("build/") or path.starts_with("examples/"))

fn tracked_files() -> Vec[str]:
    var argv: Vec[str] = Vec.new()
    argv.push("git")
    argv.push("ls-files")
    let done = run_to_files_in(".", &argv, "out/ceremony-ls.txt", "out/ceremony-ls.err")
    if done.code != 0:
        eprint("ceremony-census: git ls-files failed")
        exit_code(2)
    var files: Vec[str] = Vec.new()
    for path in (read_file("out/ceremony-ls.txt") ?? "").split("\n"):
        if counted(path): files.push(path.clone())
    files

type Census { counts: BTreeMap[str, i64] }

impl Census:
    mut fn bump(key: str):
        let now = self.counts.get(key) ?? 0
        self.counts.insert(key, now + 1)

    mut fn count_lexical(path: &str):
        let text = read_file(path) ?? ""
        let area = area_of(path)
        var lexer = Lexer.init(text, 0)
        let tokens = lexer.tokenize()
        let n = tokens.len()
        let word = (i) => if i >= 0 and i < n: text.slice(tokens.get_start(i), tokens.get_end(i)) else: ""
        for i in 0..n:
            let tag = tokens.get_tag(i)
            if tag == TokenKind.TK_DOT and i + 3 < n and tokens.get_tag(i + 2) == TokenKind.TK_L_PAREN and tokens.get_tag(i + 3) == TokenKind.TK_R_PAREN:
                if word(i + 1) == "clone": self.bump(f"clone-call\t{area}")
                if word(i + 1) == "len" and i + 4 < n and tokens.get_tag(i + 4) == TokenKind.TK_KW_AS: self.bump(f"len-cast\t{area}")
            else if tag == TokenKind.TK_KW_LET and i + 2 < n and word(i + 1) == "_" and tokens.get_tag(i + 2) == TokenKind.TK_EQ:
                self.bump(f"let-underscore\t{area}")
            else if tag == TokenKind.TK_KW_MOVE and i + 1 < n and tokens.get_tag(i + 1) == TokenKind.TK_IDENT and word(i + 1) != "self":
                self.bump(f"move-arg\t{area}")
            else if tag == TokenKind.TK_KW_COPY and i + 1 < n and tokens.get_tag(i + 1) == TokenKind.TK_IDENT:
                self.bump(f"copy-arg\t{area}")

fn typed_sites(compiler: &str) -> str:
    var argv: Vec[str] = Vec.new()
    argv.push(compiler.clone())
    argv.push("check")
    argv.push("src/main.w")
    argv.push("--ceremony-census")
    let done = run_to_files_in(".", &argv, "out/ceremony-typed.txt", "out/ceremony-typed.err")
    if done.code != 0:
        eprint(f"ceremony-census: `{compiler} check src/main.w --ceremony-census` failed (rc {done.code}); see out/ceremony-typed.err")
        exit_code(2)
    read_file("out/ceremony-typed.txt") ?? ""

fn read_record() -> HashMap[str, i64]:
    var record: HashMap[str, i64] = HashMap.new()
    for line in (read_file(RECORD) ?? "").split("\n"):
        let cols = line.split("\t")
        if cols.len() == 3: record.insert(f"{cols[0]}\t{cols[1]}", string_to_int(cols[2]))
    record

fn main:
    let argv = args()
    var write = false
    var sites_of = ""
    var compiler = "out/release/bin/with"
    var i = 1
    while i < argv.len():
        if argv[i] == "--write": write = true
        else if argv[i] == "--sites" and i + 1 < argv.len():
            i = i + 1
            sites_of = argv[i]
        else if argv[i] == "--compiler" and i + 1 < argv.len():
            i = i + 1
            compiler = argv[i]
        else:
            eprint(f"ceremony-census: unknown argument `{argv[i]}`")
            exit_code(2)
        i = i + 1
    let typed = typed_sites(compiler)
    if sites_of.len() > 0:
        for line in typed.split("\n"):
            if line.starts_with(sites_of ++ "\t"): print(line)
        return
    var census = Census { counts: BTreeMap.new() }
    for path in tracked_files(): census.count_lexical(path)
    for line in typed.split("\n"):
        let cols = line.split("\t")
        // Build-generated modules (out/gen) are not source anyone writes.
        if cols.len() == 3 and not cols[1].starts_with("out/"): census.bump(f"{cols[0]}\t{area_of(cols[1])}")
    var text = ""
    for (key, n) in census.counts: text = text ++ f"{key}\t{n}\n"
    if write:
        write_file(RECORD, text)
        print(f"ceremony-census: wrote {RECORD} ({census.counts.len()} counts)")
        return
    // The record is a ceiling: a count above it is new ceremony and fails; a
    // count below it is a cleanup and passes (lowering the record keeps the
    // ceiling tight, so a later rise cannot hide under it).
    let record = read_record()
    var rose = 0
    for (key, now) in census.counts:
        let was = record.get(key) ?? 0
        if now > was:
            rose = rose + 1
            eprint(f"ceremony-census: {key.replace("\t", " in ")} rose {was} -> {now}; remove the new ceremony, or raise the record (--write) and say why in the PR")
        else if now < was:
            print(f"ceremony-census: {key.replace("\t", " in ")} fell {was} -> {now}; lower the record with --write")
    for (key, was) in record:
        if not census.counts.contains(key) and was > 0:
            print(f"ceremony-census: {key.replace("\t", " in ")} fell {was} -> 0; lower the record with --write")
    if rose > 0: exit_code(1)
    print("ceremony-census: ok")
