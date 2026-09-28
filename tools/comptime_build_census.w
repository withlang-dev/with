// comptime_build_census -- every method name the build layer calls, against
// the comptime evaluator's built-in dispatch (#1866).
//
// The build layer (build.w, build/*.w, lib/std/build.w) runs under the seed's
// comptime evaluator whenever the native runner cannot be linked yet
// (`:seed`, any `--no-deps` action in a fresh checkout, #1797), so every
// method it calls on a built-in type must be evaluable there. This lists each
// `.name(` the layer spells, with its call count, and marks the names that
// no `method == "name"` arm in src/ComptimeEval.w handles. A marked name is
// either a user method the layer defines itself (evaluated through the
// user-method path, fine) or a built-in gap to implement.
//
//   with run tools/comptime_build_census.w            # table
//   with run tools/comptime_build_census.w --missing  # only the gaps

use std.fs
use std.process
use Lexer
use Token

fn census_files() -> Vec[str]:
    var files: Vec[str] = Vec.new()
    files.push("build.w")
    files.push("lib/std/build.w")
    for name in list_files_text("build").split("\n"):
        if name.ends_with(".w"): files.push(name.clone())
    files

/// The identifiers spelled between `.` and `(` in `text`, in source order.
fn method_calls(text: &str) -> Vec[str]:
    var out: Vec[str] = Vec.new()
    var lexer = Lexer.init(text, 0)
    let tokens = lexer.tokenize()
    let n = tokens.len()
    for i in 1..n - 1:
        if tokens.get_tag(i) != TokenKind.TK_IDENT: continue
        if tokens.get_tag(i - 1) != TokenKind.TK_DOT: continue
        if tokens.get_tag(i + 1) != TokenKind.TK_L_PAREN: continue
        out.push(text.slice(tokens.get_start(i) as i64, tokens.get_end(i) as i64))
    out

/// The names the evaluator dispatches on: every `method == "name"` arm.
fn evaluator_methods() -> Vec[str]:
    var names: Vec[str] = Vec.new()
    let key = "method == \""
    let text = read_file("src/ComptimeEval.w").unwrap()
    for line in text.split("\n"):
        var rest = line.clone()
        while rest.contains(key):
            let at = rest.index_of(key)
            rest = rest.slice(at + key.len(), rest.len())
            let close = rest.index_of("\"")
            if close < 0: break
            names.push(rest.slice(0, close))
            rest = rest.slice(close + 1, rest.len())
    names

/// The names a file defines itself (`fn name`, `fn Type.name`), so a call
/// to one is a user method the evaluator runs from its declaration; and the
/// fn-typed fields it declares (`name: fn(`), called through the fn value.
fn defined_fns(text: &str) -> Vec[str]:
    var out: Vec[str] = Vec.new()
    var lexer = Lexer.init(text, 0)
    let tokens = lexer.tokenize()
    let n = tokens.len()
    for i in 0..n - 1:
        if tokens.get_tag(i) == TokenKind.TK_IDENT and i + 2 < n and tokens.get_tag(i + 1) == TokenKind.TK_COLON and tokens.get_tag(i + 2) == TokenKind.TK_KW_FN:
            out.push(text.slice(tokens.get_start(i) as i64, tokens.get_end(i) as i64))
            continue
        if tokens.get_tag(i) != TokenKind.TK_KW_FN: continue
        if tokens.get_tag(i + 1) != TokenKind.TK_IDENT: continue
        // `fn name` and the extension form `fn Type.name`.
        var at = i + 1
        if at + 2 < n and tokens.get_tag(at + 1) == TokenKind.TK_DOT and tokens.get_tag(at + 2) == TokenKind.TK_IDENT: at = at + 2
        out.push(text.slice(tokens.get_start(at) as i64, tokens.get_end(at) as i64))
    out

fn contains_name(names: &Vec[str], name: &str) -> bool:
    for i in 0..names.len() as i32:
        if names[i] == name: return true
    false

fn index_of_name(names: &Vec[str], name: &str) -> i32:
    for i in 0..names.len() as i32:
        if names[i] == name: return i
    -1

let argv = args()
let missing_only = argv.len() > 1 and argv[1] == "--missing"
let evaluable = evaluator_methods()
var names: Vec[str] = Vec.new()
var counts: Vec[i32] = Vec.new()
var user_defined: Vec[str] = Vec.new()
// A stdlib method (IoError.message, CString.as_cstr) evaluates through the
// same user-method path as a build-layer one.
var stdlib_defined: Vec[str] = Vec.new()
for path in list_files_text("lib/std").split("\n"):
    if not path.ends_with(".w"): continue
    for name in defined_fns(read_file(path).unwrap()):
        if not contains_name(&stdlib_defined, name): stdlib_defined.push(name.clone())
for path in census_files():
    let text = read_file(path).unwrap()
    for name in defined_fns(text):
        if not contains_name(&user_defined, name): user_defined.push(name.clone())
    for name in method_calls(text):
        let found = index_of_name(&names, name)
        if found < 0:
            names.push(name.clone())
            counts.push(1)
        else:
            counts[found] = counts[found] + 1
// Alphabetical, so the table is stable across runs: pick the least
// remaining name each round.
var taken: Vec[bool] = Vec.new()
for i in 0..names.len() as i32: taken.push(false)
var gaps = 0
for round in 0..names.len() as i32:
    var best = -1
    for i in 0..names.len() as i32:
        if taken[i]: continue
        if best < 0 or names[i] < names[best]: best = i
    taken[best] = true
    let name = names[best].clone()
    var status = "evaluator"
    if not contains_name(&evaluable, name):
        status = if contains_name(&user_defined, name): "user-defined" else if contains_name(&stdlib_defined, name): "stdlib-defined" else: "MISSING"
    if status == "MISSING": gaps = gaps + 1
    if missing_only and status != "MISSING": continue
    print(f"{name}\t{counts[best]}\t{status}")
eprint(f"{names.len()} method names; {gaps} not in the evaluator's dispatch and not defined by the build layer")
