// Insert explicit `move` at method arguments selected by live compiler diagnostics.
// Sema owns the ownership decision and exact source span; this tool only validates
// token boundaries and applies source edits. Dry-run is the default.
//
//   with run tools/migrate_method_arg_moves.w <entry.w>
//   with run tools/migrate_method_arg_moves.w --apply --last-use <entry.w>

use std.process
use std.fs
use AnalysisTypes
use compiler.Compilation
use Lexer
use Token

type OwnershipSite {
    path: str,
    offset: i32,
}

fn slice(text: &str, start: isize, end: isize): text.slice(start, end)

fn source_path(path: &str) -> str:
    let embedded = "<embedded-std>/"
    if path.starts_with(embedded): "lib/" ++ slice(path, embedded.len() as i32, path.len() as i32) else: path.clone()

fn collect_sites(entry: &str) -> List[OwnershipSite]:
    let result = compiler_analyze_file(entry, "select:kind=diagnostic")
    let sites: List[OwnershipSite] = List.new()
    let message = "this parameter takes ownership of a non-Copy value"
    var unrelated = 0
    for i in 0..result.report.facts.len() as i32:
        let fact = result.report.facts[i]
        if fact.kind != AnalysisFactKind.Diagnostic or fact.flags != AnalysisDiagnosticSeverity.Error as i32:
            continue
        if fact.name != message:
            unrelated = unrelated + 1
            print("migrate-method-arg-moves: unrelated compiler error: " ++ fact.name)
            continue
        if fact.path.len() == 0 or fact.start < 0:
            print("migrate-method-arg-moves: ownership diagnostic lacks a source span")
            exit_code(1)
        let path = source_path(fact.path)
        for si in 0..sites.len() as i32:
            let old = sites[si]
            if old.path == path and old.offset == fact.start:
                print(f"migrate-method-arg-moves: duplicate compiler fact {path}:{fact.start}")
                exit_code(1)
        sites.push(OwnershipSite { path, offset: fact.start })
    if unrelated != 0:
        print(f"migrate-method-arg-moves: refusing migration with {unrelated} unrelated error(s)")
        exit_code(1)
    sites

// #691: liveness filter. The move-sites TSV (analyze <entry> move-sites)
// verdicts each transfer site; only `last-use` sites are provably safe for a
// mechanical `move` keyword. Design sites (live-after / in-loop) are skipped
// and reported — they need a human decision, not a keyword.
fn liveness_lookup(tsv: &str, key: &str) -> str:
    var line_start: i64 = 0
    var i: i64 = 0
    while i <= tsv.len():
        if i == tsv.len() or tsv[i] == 10:
            let line = tsv.slice(line_start, i)
            if line.starts_with(key ++ "\t"):
                let cols = line.split("\t")
                if cols.len() >= 5:
                    return cols[4].clone()
            line_start = i + 1
        i = i + 1
    ""

fn offset_line_col(text: &str, offset: i32) -> str:
    var line = 1
    var col = 1
    var i: i64 = 0
    while i < offset as i64 and i < text.len():
        if text[i] == 10:
            line = line + 1
            col = 1
        else:
            col = col + 1
        i = i + 1
    f"{line}:{col}"

fn line_col_offset(text: &str, want_line: i64, want_col: i64) -> i32:
    var line: i64 = 1
    var col: i64 = 1
    var i: i64 = 0
    while i < text.len():
        if line == want_line and col == want_col:
            return i as i32
        if text[i] == 10:
            line = line + 1
            col = 1
        else:
            col = col + 1
        i = i + 1
    -1

// #691: build the site list directly from a move-sites TSV (verdict column
// filters to last-use). This lets the SEED run the tool while a flip-carrying
// stage binary supplies the analysis — the tool's own dependency graph is the
// compiler, which does not compile under the flip until migration completes.
fn collect_sites_from_tsv(tsv: &str) -> List[OwnershipSite]:
    let sites: List[OwnershipSite] = List.new()
    var line_start: i64 = 0
    var i: i64 = 0
    while i <= tsv.len():
        if i == tsv.len() or tsv[i] == 10:
            let line = tsv.slice(line_start, i)
            line_start = i + 1
            if line.contains("\t") and not line.starts_with("file:"):
                let cols = line.split("\t")
                if cols.len() >= 5 and cols[4] == "last-use":
                    let loc = cols[0].split(":")
                    if loc.len() >= 3:
                        let path = loc[0].clone()
                        let text = read_file(path).unwrap_or("".clone())
                        if text.len() == 0:
                            print("migrate-method-arg-moves: cannot read " ++ path)
                            exit_code(1)
                        let offset = line_col_offset(text, bcm_parse_i64(loc[1]), bcm_parse_i64(loc[2]))
                        if offset < 0:
                            print("migrate-method-arg-moves: bad tsv location " ++ cols[0])
                            exit_code(1)
                        sites.push(OwnershipSite { path, offset })
        i = i + 1
    sites

fn bcm_parse_i64(s: &str) -> i64:
    var out: i64 = 0
    var i: i64 = 0
    while i < s.len():
        let ch = s[i]
        if ch < 48 or ch > 57:
            return out
        out = out * 10 + (ch - 48) as i64
        i = i + 1
    out

fn migrate_file(path: &str, sites: &List[OwnershipSite], apply: bool, liveness_tsv: &str) -> i32:
    let text = read_file(path).unwrap_or("".clone())
    if text.len() == 0:
        print("migrate-method-arg-moves: cannot read " ++ path)
        exit_code(1)
    var lexer = Lexer.init(text, 0)
    let tokens = lexer.tokenize()
    let offsets: List[i32] = List.new()
    let labels: List[str] = List.new()
    for i in 0..sites.len() as i32:
        let site = sites[i]
        if site.path != path: continue
        if liveness_tsv.len() > 0:
            let key = path ++ ":" ++ offset_line_col(text, site.offset)
            let verdict = liveness_lookup(liveness_tsv, key)
            if verdict != "last-use":
                print(f"migrate-method-arg-moves: design site skipped ({verdict}) {key}")
                continue
        var token = -1
        for ti in 0..tokens.len():
            if tokens.get_start(ti) == site.offset:
                token = ti
                break
        if token < 0:
            print(f"migrate-method-arg-moves: compiler span is not a token boundary {path}:{site.offset}")
            exit_code(1)
        let tag = tokens.get_tag(token)
        if tag == TokenKind.TK_KW_MOVE or tag == TokenKind.TK_KW_COPY:
            print(f"migrate-method-arg-moves: compiler selected existing ownership syntax {path}:{site.offset}")
            exit_code(1)
        offsets.push(site.offset)
        labels.push(slice(text, tokens.get_start(token), tokens.get_end(token)))

    var i = 1
    while i < offsets.len() as i32:
        var j = i
        while j > 0 and offsets[(j - 1)] > offsets[j]:
            let old_offset: i32 = offsets[(j - 1)]
            let old_label = labels[(j - 1)].clone()
            offsets[(j - 1)] = offsets[j]
            labels.slot((j - 1) as i64).set(labels[j].clone())
            offsets[j] = old_offset
            labels.slot(j as i64).set(old_label)
            j = j - 1
        i = i + 1

    for oi in 0..offsets.len() as i32:
        print(f"{path}\t{offsets[oi]}\t{labels[oi]}")
    if not apply or offsets.len() == 0: return offsets.len() as i32
    let chunks: List[str] = List.new()
    var cursor = 0
    for oi in 0..offsets.len() as i32:
        let offset = offsets[oi]
        chunks.push(slice(text, cursor, offset))
        chunks.push("move ")
        cursor = offset
    chunks.push(slice(text, cursor, text.len() as i32))
    if write_file(path, chunks.join("")) != 0:
        print("migrate-method-arg-moves: failed to write " ++ path)
        exit_code(1)
    offsets.len() as i32

fn main:
    let argv = args()
    if argv.len() < 2:
        print("usage: migrate_method_arg_moves [--apply] [--last-use|--liveness <move-sites.tsv>] <entry.w>")
        exit_code(1)
    var apply = false
    var compute_liveness = false
    var liveness_path = ""
    var entry = ""
    var ai = 1
    while ai < argv.len() as i32:
        let arg = argv[ai]
        if arg == "--apply":
            apply = true
        else: if arg == "--last-use":
            compute_liveness = true
        else: if arg == "--liveness":
            ai = ai + 1
            if ai >= argv.len() as i32:
                print("migrate-method-arg-moves: --liveness requires a path")
                exit_code(1)
            liveness_path = argv[ai].clone()
        else:
            entry = arg.clone()
        ai = ai + 1
    if entry.len() == 0:
        print("usage: migrate_method_arg_moves [--apply] [--last-use|--liveness <move-sites.tsv>] <entry.w>")
        exit_code(1)
    var liveness_tsv = ""
    if compute_liveness:
        if liveness_path.len() > 0:
            print("migrate-method-arg-moves: choose --last-use or --liveness, not both")
            exit_code(1)
        liveness_tsv = compiler_analyze_file(entry, "move-sites").text.clone()
        if liveness_tsv.len() == 0:
            print("migrate-method-arg-moves: compiler returned no move-site facts")
            exit_code(1)
    else: if liveness_path.len() > 0:
        liveness_tsv = read_file(liveness_path).unwrap_or("".clone())
        if liveness_tsv.len() == 0:
            print("migrate-method-arg-moves: cannot read liveness tsv " ++ liveness_path)
            exit_code(1)
    let sites = if entry == "--from-tsv": collect_sites_from_tsv(liveness_tsv) else: collect_sites(entry)
    let files: List[str] = List.new()
    for i in 0..sites.len() as i32:
        let path = sites[i].path
        var seen = false
        for fi in 0..files.len() as i32:
            if files[fi] == path: seen = true
        if not seen: files.push(path.clone())
    var total = 0
    for i in 0..files.len() as i32:
        total = total + migrate_file(files[i], &sites, apply, liveness_tsv)
    print(f"migrate-method-arg-moves: files={files.len() as i32} sites={total} mode=" ++ if apply: "apply" else: "dry-run")
