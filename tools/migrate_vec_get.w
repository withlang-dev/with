// Rewrite `xs.get(i)` on a List to `xs[i]` (D71: a positional collection has
// no `get`; `xs[i]` is the one spelling). Sema owns the selection: every site
// is the compiler's own "List has no 'get'" diagnostic (its location and caret
// span, read from a `with check` log); this tool only matches the call's
// parentheses with the Lexer and applies the byte edits. Dry-run is default.
//
//   with check <entry.w> 2> sites.log        # with a compiler that has the diagnostic
//   with run tools/migrate_vec_get.w [--apply] sites.log...

use std.process
use std.fs
use Lexer
use Token

type GetSite { path: str, start: i32, end: i32 }

fn slice(text: &str, start: isize, end: isize): text.slice(start, end)

fn source_path(path: &str) -> str:
    let embedded = "<embedded-std>/"
    if path.starts_with(embedded): "lib/" ++ slice(path, embedded.len() as i32, path.len() as i32) else: path.clone()

let message = "error: List has no 'get': element access is spelled 'xs[i]' (§ Element access, D71)"

fn parse_i32(s: &str) -> i32:
    var out: i32 = 0
    for i in 0..s.len() as i32:
        let ch = s[i]
        if ch < 48 or ch > 57: return out
        out = out * 10 + (ch - 48) as i32
    out

fn line_col_offset(text: &str, want_line: i32, want_col: i32) -> i32:
    var line = 1
    var col = 1
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

fn count_carets(line: &str) -> i32:
    var n: i32 = 0
    for i in 0..line.len() as i32:
        if line[i] == '^': n = n + 1
    n

// A site is three log lines: the message, ` --> path:line:col`, the source
// line, then the caret line whose `^` count is the span's byte length.
fn collect_sites(log_path: &str) -> List[GetSite]:
    let log = read_file(log_path).unwrap_or("".clone())
    let lines = log.split("\n")
    let sites: List[GetSite] = List.new()
    var li = 0
    while li < lines.len() as i32:
        if lines[li] == message and li + 3 < lines.len() as i32 and lines[(li + 1)].starts_with(" --> "):
            let loc = lines[(li + 1)]
            let parts = loc.slice(5, loc.len()).split(":")
            if parts.len() < 3:
                print(f"migrate-vec-get: bad location line: {loc}")
                exit_code(1)
            let path = source_path(parts[0])
            if path.starts_with("<"):
                // Compiler-synthesized source (a `c facade` rendering): the
                // site lives in the renderer, not in a file.
                print(f"migrate-vec-get: synthesized source skipped (fix its renderer): {loc}")
                li = li + 4
                continue
            let line = parse_i32(parts[1])
            let col = parse_i32(parts[2])
            let carets = count_carets(lines[(li + 3)])
            if carets >= 120:
                print(f"migrate-vec-get: span too long to read from the caret line: {loc}")
                exit_code(1)
            let text = read_file(path).unwrap_or("".clone())
            if text.len() == 0:
                print("migrate-vec-get: cannot read " ++ path)
                exit_code(1)
            let start = line_col_offset(text, line, col)
            if start < 0:
                print(f"migrate-vec-get: location not in file: {loc}")
                exit_code(1)
            // The log's source line must be the file's: a stage binary reports
            // its embedded std copy, which may predate an earlier rewrite.
            let shown = lines[(li + 2)]
            let bar = shown.find(" | ")
            let shown_src = if bar >= 0: shown.slice(bar + 3, shown.len()) else: "".clone()
            let line_start = line_col_offset(text, line, 1)
            var line_end = line_start as i64
            while line_end < text.len() and text[line_end] != 10: line_end = line_end + 1
            if shown_src != text.slice(line_start as i64, line_end):
                print(f"migrate-vec-get: stale site skipped (source line differs): {loc}")
                li = li + 4
                continue
            var dup = false
            for si in 0..sites.len() as i32:
                if sites[si].path == path and sites[si].start == start:
                    dup = true
            if not dup:
                sites.push(GetSite { path, start, end: start + carets })
            li = li + 4
        else:
            li = li + 1
    sites

fn is_open(tag: i32): tag == TokenKind.TK_L_PAREN or tag == TokenKind.TK_L_BRACKET or tag == TokenKind.TK_L_BRACE
fn is_close(tag: i32): tag == TokenKind.TK_R_PAREN or tag == TokenKind.TK_R_BRACKET or tag == TokenKind.TK_R_BRACE

fn migrate_file(path: &str, sites: &List[GetSite], apply: bool) -> i32:
    let text = read_file(path).unwrap_or("".clone())
    if text.len() == 0:
        print("migrate-vec-get: cannot read " ++ path)
        exit_code(1)
    var lexer = Lexer.init(text, 0)
    let tokens = lexer.tokenize()
    // Parallel edit lists: byte position, byte length, replacement (0 = `[`, 1 = `]`).
    let pos: List[i32] = List.new()
    let lens: List[i32] = List.new()
    let kinds: List[i32] = List.new()
    for i in 0..sites.len() as i32:
        let site = sites[i]
        if site.path != path: continue
        // The call node ends at its `)`; walk back to the matching `(`.
        var close = -1
        for ti in 0..tokens.len():
            if tokens.get_end(ti) == site.end and tokens.get_tag(ti) == TokenKind.TK_R_PAREN:
                close = ti
                break
        if close < 0:
            // Inside an f-string interpolation the Lexer sees one string token;
            // match the parentheses on the span's bytes instead.
            if text[(site.end - 1) as i64] != ')':
                // Not a `.get(` call in the source: a derive-synthesized call
                // reported at its declaration. Its emitter is the fix.
                print(f"migrate-vec-get: synthesized call skipped (fix its emitter) {path}:{site.start}-{site.end}")
                continue
            var bdepth = 1
            var bopen = site.end - 2
            while bopen >= site.start and bdepth > 0:
                let ch = text[bopen as i64]
                if ch == ')' or ch == ']' or ch == '}': bdepth = bdepth + 1
                else if ch == '(' or ch == '[' or ch == '{': bdepth = bdepth - 1
                if bdepth > 0: bopen = bopen - 1
            if bopen - 4 < site.start or slice(text, bopen - 4, bopen) != ".get":
                print(f"migrate-vec-get: call shape is not `.get(` {path}:{site.start}-{site.end}: {slice(text, site.start, site.end)}")
                exit_code(1)
            pos.push(bopen - 4)
            lens.push(5)
            kinds.push(0)
            pos.push(site.end - 1)
            lens.push(1)
            kinds.push(1)
            continue
        var depth = 1
        var open = close - 1
        while open >= 0 and depth > 0:
            let tag = tokens.get_tag(open)
            if is_close(tag): depth = depth + 1
            else if is_open(tag): depth = depth - 1
            if depth > 0: open = open - 1
        if open < 2 or tokens.get_tag(open) != TokenKind.TK_L_PAREN or tokens.get_tag(open - 2) != TokenKind.TK_DOT or slice(text, tokens.get_start(open - 1), tokens.get_end(open - 1)) != "get" or tokens.get_start(open - 2) < site.start:
            print(f"migrate-vec-get: call shape is not `.get(` {path}:{site.start}-{site.end}: {slice(text, site.start, site.end)}")
            exit_code(1)
        pos.push(tokens.get_start(open - 2))
        lens.push(tokens.get_end(open) - tokens.get_start(open - 2))
        kinds.push(0)
        pos.push(tokens.get_start(close))
        lens.push(1)
        kinds.push(1)

    // Insertion sort by position; every edit is a distinct byte range.
    var i = 1
    while i < pos.len() as i32:
        var j = i
        while j > 0 and pos[(j - 1)] > pos[j]:
            let tp: i32 = pos[(j - 1)]
            let tl: i32 = lens[(j - 1)]
            let tk: i32 = kinds[(j - 1)]
            pos[(j - 1)] = pos[j]
            lens[(j - 1)] = lens[j]
            kinds[(j - 1)] = kinds[j]
            pos[j] = tp
            lens[j] = tl
            kinds[j] = tk
            j = j - 1
        i = i + 1
    for ei in 1..pos.len() as i32:
        if pos[(ei - 1)] + lens[(ei - 1)] > pos[ei]:
            print(f"migrate-vec-get: overlapping edits in {path} at {pos[ei]}")
            exit_code(1)
    let count = (pos.len() / 2) as i32
    print(f"{path}\t{count}")
    if not apply or count == 0: return count
    let chunks: List[str] = List.new()
    var cursor = 0
    for ei in 0..pos.len() as i32:
        chunks.push(slice(text, cursor, pos[ei]))
        chunks.push(if kinds[ei] == 0: "[".clone() else: "]".clone())
        cursor = pos[ei] + lens[ei]
    chunks.push(slice(text, cursor, text.len() as i32))
    if write_file(path, chunks.join("")) != 0:
        print("migrate-vec-get: failed to write " ++ path)
        exit_code(1)
    count

fn main:
    let argv = args()
    var apply = false
    let logs: List[str] = List.new()
    for ai in 1..argv.len() as i32:
        if argv[ai] == "--apply": apply = true
        else: logs.push(argv[ai].clone())
    if logs.len() == 0:
        print("usage: migrate_vec_get [--apply] <check.log>...")
        exit_code(1)
    let sites: List[GetSite] = List.new()
    for li in 0..logs.len() as i32:
        let found = collect_sites(logs[li])
        for fi in 0..found.len() as i32:
            var dup = false
            for si in 0..sites.len() as i32:
                if sites[si].path == found[fi].path and sites[si].start == found[fi].start:
                    dup = true
            if not dup:
                sites.push(GetSite { path: found[fi].path.clone(), start: found[fi].start, end: found[fi].end })
    let paths: List[str] = List.new()
    for si in 0..sites.len() as i32:
        var seen = false
        for pi in 0..paths.len() as i32:
            if paths[pi] == sites[si].path: seen = true
        if not seen: paths.push(sites[si].path.clone())
    var total = 0
    for pi in 0..paths.len() as i32:
        total = total + migrate_file(paths[pi], sites, apply)
    let mode = if apply: "rewritten" else: "(dry run)"
    print(f"migrate-vec-get: {total} site(s) in {paths.len()} file(s) {mode}")
