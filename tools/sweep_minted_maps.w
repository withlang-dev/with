// sweep_minted_maps -- D196 (#2372): every `HashMap[i32|i64, V]` and
// `HashSet[i32|i64]` written in a file gains the `Minted` hasher argument,
// and the file gains `use std.collections.Minted` after its last `use`.
// The compiler's integer-keyed maps hold symbol, node and type IDs (and
// sema_pair_key packs of two): IDs the program minted. A map keyed by an
// integer the program received must be excluded by hand (`--skip path`).
//
//   with run tools/sweep_minted_maps.w [--skip path ...] <file.w> ...
//
// Token-accurate (Lexer), bracket-matched; a type already carrying a third
// argument is left alone.
use std.fs
use std.process
use Lexer
use Token

fn sweep(text: str) -> (str, isize):
    var lexer = Lexer.init(text, 0)
    let toks = lexer.tokenize()
    let n = toks.len()
    let word = (i) => if i >= 0 and i < n: text.slice(toks.get_start(i), toks.get_end(i)) else: ""
    // Insertion points: the byte before the closing bracket of each target.
    let inserts = []
    for i in 0..n:
        if toks.get_tag(i) != TokenKind.TK_IDENT: continue
        let name = word(i)
        if name != "HashMap" and name != "HashSet": continue
        if i + 2 >= n or toks.get_tag(i + 1) != TokenKind.TK_L_BRACKET: continue
        let key = word(i + 2)
        if key != "i32" and key != "i64": continue
        // Walk to the matching close, counting top-level commas.
        var depth = 0
        var commas = 0
        var j = i + 1
        var close = -1
        while j < n:
            let t = toks.get_tag(j)
            if t == TokenKind.TK_L_BRACKET: depth = depth + 1
            if t == TokenKind.TK_R_BRACKET:
                depth = depth - 1
                if depth == 0:
                    close = j
                    break
            if t == TokenKind.TK_COMMA and depth == 1: commas = commas + 1
            j = j + 1
        if close < 0: continue
        let want = if name == "HashMap": 1 else: 0
        if commas != want: continue
        inserts.push(toks.get_start(close))
    if inserts.len() == 0: return (text ++ "", 0)
    // A nested target closes before its enclosing one: apply in byte order.
    for a in 1..inserts.len():
        var b = a
        while b > 0 and inserts[b - 1] > inserts[b]:
            let t = inserts[b - 1]
            inserts[b - 1] = inserts[b]
            inserts[b] = t
            b = b - 1
    var out = ""
    var at = 0
    for p in inserts:
        out = out ++ text.slice(at, p) ++ ", Minted"
        at = p
    out = out ++ text.slice(at, text.len())
    // The import, after the last top-level `use` line.
    if not out.contains("use std.collections.Minted"):
        let lines = out.split("\n")
        var last_use = -1
        for li in 0..lines.len():
            if lines[li].starts_with("use "): last_use = li
        if last_use >= 0:
            var rebuilt = ""
            for li in 0..lines.len():
                rebuilt = rebuilt ++ lines[li]
                if li == last_use: rebuilt = rebuilt ++ "\nuse std.collections.Minted"
                if li + 1 < lines.len(): rebuilt = rebuilt ++ "\n"
            out = rebuilt
    (out, inserts.len())

fn main:
    let argv = args()
    let skips = []
    let files = []
    var i = 1
    while i < argv.len():
        if argv[i] == "--skip" and i + 1 < argv.len():
            i = i + 1
            skips.push(argv[i])
        else: files.push(argv[i])
        i = i + 1
    var total = 0
    for path in files:
        if skips.contains(path): continue
        let text = read_file(path) ?? ""
        if text.len() == 0: continue
        let (out, count) = sweep(text)
        if count == 0: continue
        write_file(path, out)
        total = total + count
        print(f"{path}: {count}")
    print(f"sweep_minted_maps: {total} map type(s) in {files.len()} file(s)")
