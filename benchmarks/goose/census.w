// Syntax census, not a verdict that every spelling is unnecessary.
// Counts compiler tokens, excluding comments and string contents.
use std.fs
use std.string.StringBuilder
use Lexer
use Token

fn main:
    var report = StringBuilder.new()
    report.push_str("# Goose port syntax census\n\nCounts from the compiler lexer, excluding comments and strings. `as` includes intentional representation and floating-point conversions; typed bindings include accumulator widths and D22 owned Copy demands. These counts locate review work, not a claim that every spelling is redundant. The runner and shared RNG adapter are excluded from workload totals.\n\n| workload | `as` tokens | `.clone()` calls | typed local bindings |\n|---|---:|---:|---:|\n")
    var total_casts: i64 = 0
    var total_clones: i64 = 0
    var total_bindings: i64 = 0
    let manifest = read_file("benchmarks/goose/suite.manifest").unwrap()
    for line in manifest.split("\n"):
        if line.len() == 0 or line.starts_with("#"): continue
        let fields = line.split("|")
        let name = fields[0]
        let source = read_file("benchmarks/goose/" ++ name ++ ".w").unwrap()
        var lexer = Lexer.init(source, 0)
        let tokens = lexer.tokenize()
        var casts: i64 = 0
        var clones: i64 = 0
        var bindings: i64 = 0
        for i in 0..tokens.len():
            let tag = tokens.get_tag(i)
            if tag == TokenKind.TK_KW_AS: casts += 1
            if tag == TokenKind.TK_DOT and i + 3 < tokens.len():
                let word = source.slice(tokens.get_start(i + 1), tokens.get_end(i + 1))
                if word == "clone" and tokens.get_tag(i + 2) == TokenKind.TK_L_PAREN and tokens.get_tag(i + 3) == TokenKind.TK_R_PAREN: clones += 1
            if tag == TokenKind.TK_KW_LET or tag == TokenKind.TK_KW_VAR:
                if i + 2 < tokens.len() and tokens.get_tag(i + 2) == TokenKind.TK_COLON: bindings += 1
        report.push_str(f"| {name} | {casts} | {clones} | {bindings} |\n")
        total_casts += casts
        total_clones += clones
        total_bindings += bindings
    report.push_str(f"| **total** | **{total_casts}** | **{total_clones}** | **{total_bindings}** |\n")
    report.push_str("\nReview categories and storage choices are in [README.md](README.md). Generation width is tracked in [#2279](https://github.com/withlang-dev/with/issues/2279). D111 comparisons should record both measurement changes and removed clone spellings.\n")
    let output = report.to_str()
    if write_file("benchmarks/goose/census.md", output) != 0: panic("cannot write census")
    print(output)
