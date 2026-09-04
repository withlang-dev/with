// tools/annotate_receivers.w — D7 enforce-first Pass 1: give every by-value
// `self: Type` receiver an explicit mode from live compiler analysis facts.
//
// Sema computes the finalized receiver effect and proves declaration coverage.
// This tool only tokenizes the exact declaration span and rewrites it in place:
//   read  `fn`      →  self: &Self
//   mut   `mut fn`  →  mut self: <Type>   (prepend `mut `)
//   move  `move fn` →  move self: <Type>  (prepend `move `)
// Already explicit receivers are left untouched. Any mode-less receiver without an
// exact proven compiler fact aborts the path before a file is written.
//
//   with run tools/annotate_receivers.w src/Foo.w lib/std/x.w ...

use std.process
use Lexer
use Token
use AnalysisTypes
use compiler.Compilation

extern fn with_fs_read_file(path: &str) -> str
extern fn with_fs_list_files(path: &str) -> str
extern fn with_fs_write_file(path: &str, data: &str) -> i32

fn slice(text: str, a: i32, b: i32): text.slice(a as i64, b as i64)

type ReceiverModeFacts {
    lines: Vec[i32],
    columns: Vec[i32],
    modes: Vec[str],
    unproven: i32,
}

fn line_for_offset(text: str, offset: i32) -> i32:
    var line = 1
    for i in 0..offset:
        if text[i] as i32 == 10:
            line = line + 1
    line

fn column_for_offset(text: str, offset: i32) -> i32:
    var start = offset - 1
    while start >= 0 and text[start] as i32 != 10:
        start = start - 1
    offset - start

fn exact_mode(facts: &ReceiverModeFacts, line: i32, column: i32) -> str:
    var nearest = -1
    var nearest_column = -1
    for i in 0..facts.lines.len() as i32:
        if facts.lines[i] == line and facts.columns[i] == column:
            return facts.modes[i]
        // AST declaration spans start at modifiers (`pub`, `unsafe`, `async`),
        // while the token rewrite anchors at `fn`. Use the nearest preceding
        // fact on the same line when no exact column exists.
        let fact_column = facts.columns[i]
        if facts.lines[i] == line and fact_column < column and fact_column > nearest_column:
            nearest = i
            nearest_column = fact_column
    if nearest >= 0: facts.modes[nearest] else: ""

fn compiler_receiver_modes(path: str) -> ReceiverModeFacts:
    let result = compiler_analyze_file(path, "select:kind=declaration")
    var facts = ReceiverModeFacts {
        lines: Vec.new(),
        columns: Vec.new(),
        modes: Vec.new(),
        unproven: 0,
    }
    for i in 0..result.report.facts.len() as i32:
        let fact = result.report.facts[i]
        if fact.kind != AnalysisFactKind.Declaration or fact.path != path:
            continue
        let declared = fact.flags & 255
        if declared == AnalysisReceiverMode.Read as i32 or declared == AnalysisReceiverMode.Mut as i32 or declared == AnalysisReceiverMode.Move as i32: continue
        if declared != AnalysisReceiverMode.Missing as i32: continue
        // Bit 1024 means Sema has a real signature whose finalized effects
        // contribute to this declaration. Zero observed effects without a
        // signature is not proof of a read receiver.
        if fact.flags & (AnalysisDeclarationFlag.ReceiverProven as i32) == 0:
            facts.unproven = facts.unproven + 1
            continue
        let mode = analysis_receiver_keyword(analysis_required_receiver_mode(fact.effects))
        if mode.len() == 0:
            continue
        facts.lines.push(fact.line)
        facts.columns.push(fact.column)
        facts.modes.push(mode)
    facts

fn annotate_file(path: str, exact_facts: &ReceiverModeFacts) -> i32:
    let text = unsafe { with_fs_read_file(path) }
    let tlen = text.len() as i32
    if tlen == 0:
        return 0
    var lexer = Lexer.init(text, 0)
    let tokens = lexer.tokenize()
    let n = tokens.len()

    // (start, end, replacement) splices, ascending.
    var starts: Vec[i32] = Vec.new()
    var ends: Vec[i32] = Vec.new()
    var repls: Vec[str] = Vec.new()
    var count = 0
    var candidates = 0

    var i = 0
    while i < n:
        if tokens.get_tag(i) != TokenKind.TK_KW_FN:
            i = i + 1
            continue
        let name_idx = i + 1
        if name_idx >= n or tokens.get_tag(name_idx) != TokenKind.TK_IDENT:
            i = i + 1
            continue
        var k = name_idx + 1
        if name_idx + 2 < n and tokens.get_tag(name_idx + 1) == TokenKind.TK_DOT and tokens.get_tag(name_idx + 2) == TokenKind.TK_IDENT:
            k = name_idx + 3

        // skip optional method type params, reach `(`
        if k < n and tokens.get_tag(k) == TokenKind.TK_L_BRACKET:
            var bd = 0
            while k < n:
                let bt = tokens.get_tag(k)
                if bt == TokenKind.TK_L_BRACKET:
                    bd = bd + 1
                else if bt == TokenKind.TK_R_BRACKET:
                    bd = bd - 1
                    if bd == 0:
                        k = k + 1
                        break
                k = k + 1
        if k >= n or tokens.get_tag(k) != TokenKind.TK_L_PAREN:
            i = i + 1
            continue

        // first param must be a MODE-LESS `self` (no mut/move keyword)
        var p = k + 1
        while p < n and tokens.get_tag(p) == TokenKind.TK_NEWLINE:
            p = p + 1
        if p >= n or tokens.get_tag(p) != TokenKind.TK_IDENT or slice(text, tokens.get_start(p), tokens.get_end(p)) != "self":
            i = i + 1
            continue
        // must be `self :` with a value type (skip if next is `,`/`)` — malformed)
        var ct = p + 1
        while ct < n and tokens.get_tag(ct) == TokenKind.TK_NEWLINE:
            ct = ct + 1
        if ct >= n or tokens.get_tag(ct) != TokenKind.TK_COLON:
            i = i + 1
            continue
        // receiver type spans after `:` to the top-level `,` or `)`
        var tstart = ct + 1
        while tstart < n and tokens.get_tag(tstart) == TokenKind.TK_NEWLINE:
            tstart = tstart + 1
        // if the type already begins with `&`, it is a read borrow — skip
        if tstart < n and tokens.get_tag(tstart) == TokenKind.TK_AMPERSAND:
            i = i + 1
            continue
        candidates = candidates + 1
        var depth = 0
        var q = tstart
        while q < n:
            let t = tokens.get_tag(q)
            if t == TokenKind.TK_L_PAREN or t == TokenKind.TK_L_BRACKET:
                depth = depth + 1
            else if t == TokenKind.TK_R_BRACKET:
                depth = depth - 1
            else if t == TokenKind.TK_R_PAREN:
                if depth == 0:
                    break
                depth = depth - 1
            else if t == TokenKind.TK_COMMA and depth == 0:
                break
            q = q + 1

        let mode = exact_mode(exact_facts, line_for_offset(text, tokens.get_start(i)), column_for_offset(text, tokens.get_start(i)))
        if mode == "":
            i = i + 1
            continue
        if mode == "fn":
            // replace `self: <Type>` with `self: &Self`: keep `self`, replace type.
            starts.push(tokens.get_start(tstart))
            ends.push(tokens.get_start(q))
            repls.push("&Self")
        else if mode == "mut fn":
            starts.push(tokens.get_start(p))
            ends.push(tokens.get_start(p))
            repls.push("mut ")
        else if mode == "move fn":
            starts.push(tokens.get_start(p))
            ends.push(tokens.get_start(p))
            repls.push("move ")
        count = count + 1
        i = q + 1

    let m = starts.len() as i32
    if count != candidates:
        print(f"error: {path}: token audit found {candidates} mode-less receivers but compiler contracts proved {count}; file left unchanged")
        return -1
    if m == 0:
        return 0
    var result = ""
    var prev = 0
    for e in 0..m:
        result = result ++ slice(text, prev, starts[e]) ++ repls[e]
        prev = ends[e]
    result = result ++ slice(text, prev, tlen)
    let _ = unsafe { with_fs_write_file(path, result) }
    print(f"{path}: annotated {count}")
    count

fn file_has_mode_less_receiver(path: str) -> bool:
    let text = unsafe { with_fs_read_file(path) }
    if text.len() == 0:
        return false
    var lexer = Lexer.init(text, 0)
    let tokens = lexer.tokenize()
    var i = 0
    while i < tokens.len():
        if tokens.get_tag(i) != TokenKind.TK_KW_FN:
            i = i + 1
            continue
        var prefix = i - 1
        while prefix >= 0 and tokens.get_tag(prefix) == TokenKind.TK_NEWLINE:
            prefix = prefix - 1
        if prefix >= 0 and (tokens.get_tag(prefix) == TokenKind.TK_KW_MUT or tokens.get_tag(prefix) == TokenKind.TK_KW_MOVE):
            i = i + 1
            continue
        var k = i + 2
        if i + 3 < tokens.len() and tokens.get_tag(i + 2) == TokenKind.TK_DOT:
            k = i + 4
        if k < tokens.len() and tokens.get_tag(k) == TokenKind.TK_L_BRACKET:
            var depth = 1
            k = k + 1
            while k < tokens.len() and depth > 0:
                if tokens.get_tag(k) == TokenKind.TK_L_BRACKET: depth = depth + 1
                else if tokens.get_tag(k) == TokenKind.TK_R_BRACKET: depth = depth - 1
                k = k + 1
        if k >= tokens.len() or tokens.get_tag(k) != TokenKind.TK_L_PAREN:
            i = i + 1
            continue
        var p = k + 1
        while p < tokens.len() and tokens.get_tag(p) == TokenKind.TK_NEWLINE:
            p = p + 1
        if p < tokens.len() and tokens.get_tag(p) == TokenKind.TK_IDENT and slice(text, tokens.get_start(p), tokens.get_end(p)) == "self":
            var colon = p + 1
            while colon < tokens.len() and tokens.get_tag(colon) == TokenKind.TK_NEWLINE:
                colon = colon + 1
            if colon < tokens.len() and tokens.get_tag(colon) == TokenKind.TK_COLON:
                var type_start = colon + 1
                while type_start < tokens.len() and tokens.get_tag(type_start) == TokenKind.TK_NEWLINE:
                    type_start = type_start + 1
                if type_start < tokens.len() and tokens.get_tag(type_start) != TokenKind.TK_AMPERSAND:
                    return true
        i = i + 1
    false

fn path_excluded(path: str, excludes: &Vec[str]) -> bool:
    for i in 0..excludes.len() as i32:
        if path == excludes[i]:
            return true
    false

fn annotate_integrated_file(path: str, excludes: &Vec[str]) -> i32:
    if path_excluded(path, excludes) or not file_has_mode_less_receiver(path):
        return 0
    let facts = compiler_receiver_modes(path)
    if facts.unproven > 0:
        print(f"error: {path}: compiler found {facts.unproven} mode-less receiver declarations without finalized signatures; file left unchanged")
        return -1
    if facts.lines.len() == 0:
        print(f"error: {path}: token audit found a mode-less receiver but compiler produced no declaration fact; file left unchanged")
        return -1
    annotate_file(path, &facts)

fn annotate_integrated_path(path: str, excludes: &Vec[str]) -> i32:
    if path.ends_with(".w"):
        return annotate_integrated_file(path, excludes)
    let listing = unsafe { with_fs_list_files(path) }
    var changed = 0
    var failures = 0
    var start = 0
    for i in 0..listing.len() as i32 + 1:
        if i != listing.len() as i32 and listing[i] as i32 != 10:
            continue
        if i > start:
            let file = slice(listing, start, i)
            if file.ends_with(".w"):
                let result = annotate_integrated_file(file, excludes)
                if result < 0:
                    failures = failures + 1
                else:
                    changed = changed + result
        start = i + 1
    if failures > 0:
        print(f"error: {path}: {failures} files lacked complete compiler receiver facts")
        return -1
    changed

fn main:
    let argv = args()
    if argv.len() < 2:
        print("usage: annotate_receivers [--exclude file.w ...] <file-or-dir> [file-or-dir ...]")
        exit_code(1)
    let excludes: Vec[str] = Vec.new()
    let paths: Vec[str] = Vec.new()
    var arg = 1
    while arg < argv.len() as i32:
        if argv[arg] == "--exclude":
            if arg + 1 >= argv.len() as i32:
                print("error: --exclude requires a file path")
                exit_code(1)
            arg = arg + 1
            excludes.push(argv[arg])
        else:
            paths.push(argv[arg])
        arg = arg + 1
    if paths.len() == 0:
        print("error: no annotation paths supplied")
        exit_code(1)
    var total = 0
    var failures = 0
    for i in 0..paths.len() as i32:
        let changed = annotate_integrated_path(paths[i], &excludes)
        if changed < 0: failures = failures + 1
        else: total = total + changed
    print(f"total: {total} receivers annotated from compiler facts")
    if failures != 0:
        print(f"error: {failures} paths contain unresolved receiver declarations")
        exit_code(1)
