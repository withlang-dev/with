// ceremony_census -- count the known ceremony patterns across the tree
// (CLAUDE.md "Ceremony is a design defect, not a user error").
//
// Lexical patterns are counted from the tokens of every tracked .w file
// under src/, lib/, rt/, tools/, build/, build.w and examples/ (test/ fixtures
// spell these forms on purpose and are not counted):
//   clone-call       `.clone()`
//   len-cast         `.len() as`
//   let-underscore   `let _ =`
//   move-arg         `move x` (not `move fn` / `move self`)
//   copy-arg         `copy x`
//   vec-name         the identifier `Vec` (D118: it names no type; target 0)
//   lit-ptr-len      `"…" as *const u8, N` — a literal cast to its bytes
//                    with a hand-counted length (a literal is a str: pass it)
//   bool-as-if-1-0   `if c: 1 else: 0` / `if c: 0 else: 1` — a bool spelled
//                    as a number by hand (`c as i32` is the spelling, D177)
// Typed patterns come from one compilation of src/main.w, which covers the
// compiler and lib/std (`with check --ceremony-census`):
//   str-clone              `.clone()` on a str
//   ref-at-ref-param       an explicit `&x` at a `&T` parameter
//   some-at-option-demand  `Some(x)` where an Option is demanded
//   str-move               `move x` where x is a str binding (a field
//                          `move` vacates it, D82, and is not counted)
//   str-view-copy-annotation  `let s: str = <a view of str>` (D179: the
//                          unannotated binding takes the str)
//
// The bar is main's own counts, recorded when main's compiler is installed
// (`:install-user` publishes `--record-bar`'s file) into the green store beside green.tsv
// ($WITH_GREEN_DIR, else ~/.local/with-green). A tree is measured against it:
// a count that falls passes, and the bar falls with it at the next reseed; a
// count that rises fails unless build/ceremony-allowances.tsv grants it, one
// line `pattern<TAB>area<TAB>bar<TAB>ceiling<TAB>why` (the PR says why too).
// A grant names the bar it was made against and lapses once the bar moves.
//
//   with run tools/ceremony_census.w                   # check against the bar
//   with run tools/ceremony_census.w --record-bar FILE # write this tree's counts as a bar
//   with run tools/ceremony_census.w --sites PATTERN   # list one typed pattern's sites
//   with run tools/ceremony_census.w --diff REV        # iterate tier: lexical counts of the
//                                                      # files changed vs REV, worktree vs REV;
//                                                      # typed patterns need the full run
//   --compiler PATH                                    # default out/release/bin/with

use std.fs
use std.process
use std.string
use Lexer
use Token

let ALLOWANCES = "build/ceremony-allowances.tsv"

fn green_dir():
    let dir = env("WITH_GREEN_DIR")
    if dir.len() > 0: dir.clone() else: env("HOME") ++ "/.local/with-green"

fn area_of(path: &str):
    if path.starts_with("<embedded-std>/"): "lib"
    else if path == "build.w": "build"
    else: path.slice(0, path.find("/"))

fn counted(path: &str) -> bool:
    path.ends_with(".w") and (path == "build.w" or path.starts_with("src/") or path.starts_with("lib/") or path.starts_with("rt/") or path.starts_with("tools/") or path.starts_with("build/") or path.starts_with("examples/"))

// D112: a directory holding a corpus.stamp is a migrated corpus, generated
// code that carries its migrator generation's idioms; it is never counted
// as written With.
fn under_any(path: &str, dirs: &List[str]) -> bool:
    for dir in dirs:
        if path.starts_with(dir): return true
    false

fn corpus_dirs(listing: &List[str]) -> List[str]:
    var generated: List[str] = List.new()
    for path in listing:
        if path.ends_with("/corpus.stamp"): generated.push(path.slice(0, path.len() - "corpus.stamp".len()))
    generated

fn git_listing(args: &List[str], out_name: &str) -> List[str]:
    let done = run_to_files_in(".", args, f"out/ceremony-{out_name}.txt", f"out/ceremony-{out_name}.err")
    if done.code != 0:
        eprint("ceremony-census: git listing failed")
        exit_code(2)
    (read_file(f"out/ceremony-{out_name}.txt") ?? "").split("\n")

fn tracked_files() -> List[str]:
    let listing = git_listing(&["git", "ls-files"], "ls")
    let generated = corpus_dirs(&listing)
    var files: List[str] = List.new()
    for path in listing:
        if counted(path) and not under_any(path, generated): files.push(path)
    files

// The counted files a change touches: modified against `rev`, plus new
// untracked ones. Used by --diff, the iterate-tier shape.
fn changed_counted_files(rev: &str) -> List[str]:
    var argv: List[str] = List.new()
    argv.push("git")
    argv.push("ls-files")
    let listing = git_listing(&argv, "ls")
    let generated = corpus_dirs(&listing)
    var files: List[str] = List.new()
    var diff_argv: List[str] = List.new()
    diff_argv.push("git")
    diff_argv.push("diff")
    diff_argv.push("--name-only")
    let rev_arg: str = rev
    diff_argv.push(rev_arg)
    diff_argv.push("--")
    for path in git_listing(&diff_argv, "diff"):
        if counted(path) and not under_any(path, generated) and not files.contains(path): files.push(path)
    var new_argv: List[str] = List.new()
    new_argv.push("git")
    new_argv.push("ls-files")
    new_argv.push("--others")
    new_argv.push("--exclude-standard")
    for path in git_listing(&new_argv, "new"):
        if counted(path) and not under_any(path, generated) and not files.contains(path): files.push(path)
    files

// The text of `path` at `rev`, "" when it did not exist there.
fn text_at_rev(rev: &str, path: &str) -> str:
    var argv: List[str] = List.new()
    argv.push("git")
    argv.push("show")
    argv.push(f"{rev}:{path}")
    let done = run_to_files_in(".", &argv, "out/ceremony-show.txt", "out/ceremony-show.err")
    if done.code != 0: return ""
    read_file("out/ceremony-show.txt") ?? ""

type Census { counts: BTreeMap[str, i64] }

impl Census:
    mut fn bump(key: str):
        let now = self.counts.get(key) ?? 0
        self.counts.insert(key, now + 1)

    mut fn count_lexical(path: &str):
        self.count_lexical_text(read_file(path) ?? "", area_of(path))

    mut fn count_lexical_text(text: &str, area: &str):
        let source: str = text
        var lexer = Lexer.init(source, 0)
        let tokens = lexer.tokenize()
        let n = tokens.len()
        let word = (i) => if i >= 0 and i < n: source.slice(tokens.get_start(i), tokens.get_end(i)) else: ""
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
            else if tag == TokenKind.TK_STRING_LIT and i + 6 < n and tokens.get_tag(i + 1) == TokenKind.TK_KW_AS and tokens.get_tag(i + 2) == TokenKind.TK_STAR and word(i + 3) == "const" and word(i + 4) == "u8" and tokens.get_tag(i + 5) == TokenKind.TK_COMMA and tokens.get_tag(i + 6) == TokenKind.TK_INT_LIT:
                self.bump(f"lit-ptr-len\t{area}")
            else if tag == TokenKind.TK_IDENT and word(i) == "Vec":
                self.bump(f"vec-name\t{area}")
            else if tag == TokenKind.TK_COLON and i + 4 < n and tokens.get_tag(i + 1) == TokenKind.TK_INT_LIT and tokens.get_tag(i + 2) == TokenKind.TK_KW_ELSE and tokens.get_tag(i + 3) == TokenKind.TK_COLON and tokens.get_tag(i + 4) == TokenKind.TK_INT_LIT:
                let a = word(i + 1)
                let b = word(i + 4)
                if (a == "1" and b == "0") or (a == "0" and b == "1"): self.bump(f"bool-as-if-1-0\t{area}")

fn typed_sites(compiler: &str) -> str:
    var argv: List[str] = List.new()
    argv.push(compiler.clone())
    argv.push("check")
    argv.push("src/main.w")
    argv.push("--ceremony-census")
    let done = run_to_files_in(".", &argv, "out/ceremony-typed.txt", "out/ceremony-typed.err")
    if done.code != 0:
        eprint(f"ceremony-census: `{compiler} check src/main.w --ceremony-census` failed (rc {done.code}); see out/ceremony-typed.err")
        exit_code(2)
    read_file("out/ceremony-typed.txt") ?? ""

fn read_counts(path: &str) -> HashMap[str, i64]:
    var counts: HashMap[str, i64] = HashMap.new()
    for line in (read_file(path) ?? "").split("\n"):
        let cols = line.split("\t")
        if cols.len() == 3: counts.insert(f"{cols[0]}\t{cols[1]}", string_to_int(cols[2]))
    counts

// The ceiling each grant allows, keyed like the counts, for grants made
// against the bar as it stands.
fn read_allowances(bar: &HashMap[str, i64]) -> HashMap[str, i64]:
    var allowed: HashMap[str, i64] = HashMap.new()
    for line in (read_file(ALLOWANCES) ?? "").split("\n"):
        let cols = line.split("\t")
        if cols.len() < 5 or line.starts_with("#"): continue
        let key = f"{cols[0]}\t{cols[1]}"
        if string_to_int(cols[2]) == bar.get(key) ?? 0: allowed.insert(key, string_to_int(cols[3]))
    allowed

fn main:
    let argv = args()
    var record_bar_to = ""
    var sites_of = ""
    var diff_rev = ""
    var compiler = "out/release/bin/with"
    var i = 1
    while i < argv.len():
        if argv[i] == "--record-bar" and i + 1 < argv.len():
            i = i + 1
            record_bar_to = argv[i]
        else if argv[i] == "--sites" and i + 1 < argv.len():
            i = i + 1
            sites_of = argv[i]
        else if argv[i] == "--diff" and i + 1 < argv.len():
            i = i + 1
            diff_rev = argv[i]
        else if argv[i] == "--compiler" and i + 1 < argv.len():
            i = i + 1
            compiler = argv[i]
        else:
            eprint(f"ceremony-census: unknown argument `{argv[i]}`")
            exit_code(2)
        i = i + 1
    if diff_rev.len() > 0:
        var before = Census { counts: BTreeMap.new() }
        var after = Census { counts: BTreeMap.new() }
        let files = changed_counted_files(diff_rev)
        for path in files:
            before.count_lexical_text(text_at_rev(diff_rev, path), area_of(path))
            after.count_lexical(path)
        var rose = 0
        for (key, now) in after.counts:
            let was = before.counts.get(key) ?? 0
            if now > was:
                rose = rose + 1
                eprint(f"ceremony-census: {key.replace("\t", " in ")} rose {was} -> {now} in the files changed vs {diff_rev}; remove the new ceremony (typed patterns are covered by the full run)")
            else if now < was:
                print(f"ceremony-census: {key.replace("\t", " in ")} fell {was} -> {now} in the files changed vs {diff_rev}")
        if rose > 0: exit_code(1)
        print(f"ceremony-census: diff ok ({files.len()} counted files changed vs {diff_rev}; lexical patterns only)")
        return
    let typed = typed_sites(compiler)
    if sites_of.len() > 0:
        for line in typed.split("\n"):
            if line.starts_with(sites_of ++ "\t"): print(line)
        return
    var census = Census { counts: BTreeMap.new() }
    for path in tracked_files(): census.count_lexical(path)
    // D112 holds for typed sites too: a corpus is generated code. Without
    // this the count depended on the compiler that recorded it: a release
    // binary links the corpora as .wo bundles and never checks their source,
    // a :dev stage1 checks it and counted 40 corpus sites of
    // some-at-option-demand under lib.
    let generated = corpus_dirs(&git_listing(&["git", "ls-files"], "ls"))
    for line in typed.split("\n"):
        let cols = line.split("\t")
        if cols.len() < 3: continue
        let path = if cols[1].starts_with("<embedded-std>/"): "lib/" ++ cols[1].slice("<embedded-std>/".len(), cols[1].len()) else: cols[1]
        // Build-generated modules (out/gen) are not source anyone writes.
        if not path.starts_with("out/") and not under_any(path, &generated): census.bump(f"{cols[0]}\t{area_of(cols[1])}")
    let bar_file = green_dir() ++ "/ceremony-bar.tsv"
    if record_bar_to.len() > 0:
        var text = ""
        for (key, n) in census.counts: text = text ++ f"{key}\t{n}\n"
        if write_file(record_bar_to, text) != 0:
            eprint(f"ceremony-census: could not write {record_bar_to}")
            exit_code(2)
        print(f"ceremony-census: wrote the bar to {record_bar_to} ({census.counts.len()} counts)")
        return
    if not file_exists(bar_file):
        print(f"ceremony-census: no bar at {bar_file} yet; the next reseed (:install-user) records main's counts")
        return
    let bar = read_counts(bar_file)
    let allowed = read_allowances(&bar)
    var rose = 0
    for (key, now) in census.counts:
        let was = bar.get(key) ?? 0
        let ceiling = allowed.get(key) ?? was
        if now > ceiling:
            rose = rose + 1
            eprint(f"ceremony-census: {key.replace("\t", " in ")} rose {was} -> {now}; remove the new ceremony, or grant it in {ALLOWANCES} (`{key}\t{was}\t{now}\t<why>`) and say why in the PR")
        else if now < was:
            print(f"ceremony-census: {key.replace("\t", " in ")} fell {was} -> {now}; the bar follows at the next reseed")
    if rose > 0: exit_code(1)
    print("ceremony-census: ok")
