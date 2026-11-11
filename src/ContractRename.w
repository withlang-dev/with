// `with fix-contracts [--apply] <path>...`: respells the With Contract
// Language's old keyword in a user's own files (Eric's ruling, 2026-11-11:
// the facade language is the With Contract Language; `c facade name:` is
// `c contract name:`, and a contract module is `contracts.<name>`).
//
// Two token shapes change and nothing else:
//   c facade <name>       at the start of a line   ->   c contract <name>
//   use facades.<name>                             ->   use contracts.<name>
// The Lexer finds them, so the word inside a string, a comment or an
// identifier is never touched: "facade" also names the hand-written library
// layer over a migrated engine (D37), and that meaning keeps the word.
//
// Without `--apply` it lists what it would change. A directory is walked
// for `.w` files.

use std.process
use std.builtins.eprint
use Lexer
use Token
use rt.rt_core

type ContractEdit { start: i32, end: i32, text: str }

fn cr_token_is(source: &str, tokens: &TokenList, index: i32, text: &str) -> bool:
    index < tokens.len() and tokens.get_tag(index) == TokenKind.TK_IDENT and source.slice(tokens.get_start(index) as i64, tokens.get_end(index) as i64) == text

/// The respellings one source needs, in source order.
fn contract_rename_edits(source: &str) -> List[ContractEdit]:
    var lexer = Lexer.init(source, 0)
    let tokens = lexer.tokenize()
    let edits = []
    var at: i32 = 0
    while at + 2 < tokens.len():
        let start = tokens.get_start(at)
        // `c facade name` with `c` the first token of its line: a block
        // header. Two names side by side are never an expression.
        if cr_token_is(source, tokens, at, "c") and cr_token_is(source, tokens, at + 1, "facade") and tokens.get_tag(at + 2) == TokenKind.TK_IDENT and column_of(source, start) == line_indent_of(source, start):
            edits.push(ContractEdit { start: tokens.get_start(at + 1), end: tokens.get_end(at + 1), text: "contract" })
        if tokens.get_tag(at) == TokenKind.TK_KW_USE and cr_token_is(source, tokens, at + 1, "facades") and tokens.get_tag(at + 2) == TokenKind.TK_DOT:
            edits.push(ContractEdit { start: tokens.get_start(at + 1), end: tokens.get_end(at + 1), text: "contracts" })
        at += 1
    edits

/// `source` with `edits` applied.
fn contract_rename_apply(source: &str, edits: &List[ContractEdit]) -> str:
    var out = ""
    var from: i32 = 0
    for edit in edits:
        out = out ++ source.slice(from as i64, edit.start as i64) ++ edit.text
        from = edit.end
    out ++ source.slice(from as i64, source.len())

fn cr_line_of(source: &str, at: i32) -> i32:
    var line: i32 = 1
    for byte in source.slice(0, at as i64).bytes():
        if byte == '\n': line += 1
    line

/// The `.w` files `path` names: itself, or every one beneath a directory.
fn cr_sources(path: &str) -> List[str]:
    let files = []
    if path.ends_with(".w"):
        files.push(path.to_owned())
        return files
    for entry in with_fs_list_files(path).split("\n"):
        if entry.ends_with(".w"): files.push(entry.to_owned())
    files

fn run_fix_contracts() -> i32:
    let argv = args()
    var apply = false
    let paths = []
    var i = 2
    while i < argv.len():
        if argv[i] == "--apply": apply = true
        else if argv[i] == "--list": apply = false
        else: paths.push(argv[i].to_owned())
        i += 1
    if paths.len() == 0:
        print("usage: with fix-contracts [--list|--apply] <file.w or directory>...")
        return 2
    var changes = 0
    var changed_files = 0
    for path in paths:
        for file in cr_sources(path):
            let source = with_fs_read_file(file)
            let edits = contract_rename_edits(source)
            if edits.len() == 0: continue
            changed_files += 1
            for edit in edits:
                changes += 1
                let old = source.slice(edit.start as i64, edit.end as i64)
                print(f"{file}:{cr_line_of(source, edit.start)}: {old} -> {edit.text}")
            if apply and with_fs_write_file(file, contract_rename_apply(source, edits)) != 0:
                eprint(f"fix-contracts: could not write {file}")
                return 1
    let verb = if apply: "respelled" else: "to respell (run with --apply)"
    print(f"fix-contracts: {changes} {verb} in {changed_files} file(s)")
    0
