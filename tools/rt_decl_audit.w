// D30 R2c: audit every `extern fn with_*` and `extern fn rt_*` decl against
// the rt definition of the same name, plus compiled `rt.wi` interfaces (when
// built), cross-backend rt return agreement, and `runtime/with_runtime.h` C
// prototypes. #761's corruption class is one symbol whose ABI contract is
// derived twice — so the rt def (with Sema's D43-inferred return type from
// `rt.wi`) is truth and any decl, peer backend, or C header prototype that
// disagrees is a live divergence.
//
//   with run tools/rt_decl_audit.w        # from the repo root; exits 1 on any divergence
//
// Note: `TokenList` is private to src/Token.w, so all token work has to stay
// inside one function; normalization cannot be factored out.
use std.fs
use std.process
use Lexer
use Token

fn owned(s: &str): s ++ ""

// A `fn` def's return type ends at `:` or `{`; an `extern fn` decl has no body,
// so it ends at the line break instead.
fn ends_return_type(tag: i32) -> bool:
    tag == TokenKind.TK_COLON or tag == TokenKind.TK_L_BRACE or tag == TokenKind.TK_NEWLINE or tag == TokenKind.TK_EOF

fn line_of(text: &str, off: i32) -> i32:
    var n: i32 = 1
    var i = 0
    while i < off:
        if text[i] == 10: n = n + 1
        i = i + 1
    n

fn wi_path_for_rt_source(path: &str) -> str:
    if path.ends_with("linux_x86_64.w"): return "out/lib/cross/linux_x86_64/rt.wi"
    if path.ends_with("linux_aarch64.w"): return "out/lib/cross/linux_aarch64/rt.wi"
    if path.ends_with("windows_x86_64.w") or path.ends_with("fiber_core_windows.w"): return "out/lib/cross/windows_x86_64/rt.wi"
    if path.ends_with("windows_aarch64.w"): return "out/lib/cross/windows_aarch64/rt.wi"
    if path.ends_with("wasm.w") or path.ends_with("fiber_stubs.w"): return "out/lib/cross/wasm32/rt.wi"
    "out/lib/rt.wi"

// Load `wi_path|fn_name -> ret_type` from compiled `rt.wi` bundles when present,
// so unannotated `pub fn`s in `rt/*.w` are audited with Sema's D43-inferred
// return type rather than blindly assumed `->Unit`.
fn load_wi_returns() -> HashMap[str, str]:
    var out: HashMap[str, str] = HashMap.new()
    let wis = [
        "out/lib/rt.wi",
        "out/lib/cross/linux_x86_64/rt.wi",
        "out/lib/cross/linux_aarch64/rt.wi",
        "out/lib/cross/windows_x86_64/rt.wi",
        "out/lib/cross/windows_aarch64/rt.wi",
        "out/lib/cross/wasm32/rt.wi",
    ]
    for wi in wis:
        let text = read_file(wi) ?? ""
        if text.len() == 0: continue
        for raw in text.split("\n"):
            let line = raw.trim()
            if not line.contains("fn "): continue
            let fn_at = line.find("fn ") + 3
            let lp = line.find("(")
            if lp < fn_at: continue
            let name = line.slice(fn_at, lp).trim()
            let arrow = line.rfind("->")
            if arrow < lp: continue
            let ret = line.slice(arrow + 2, line.len()).trim().replace(" ", "")
            out.insert(f"{wi}|{name}", owned(ret))
    out

// One "name|sig|pins|file:line" record per matching decl.
fn scan(path: &str, want_extern: bool, aliases: &List[str], wi_returns: &HashMap[str, str]) -> List[str]:
    var found: List[str] = List.new()
    let text = read_file(path) ?? ""
    if text.len() == 0: return found
    var lexer = Lexer.init(text.slice(0, text.len()), 0)
    let toks = lexer.tokenize()
    let n = toks.len()
    let wi_for_file = if not want_extern: wi_path_for_rt_source(path) else: ""
    for i in 0..n:
        if toks.get_tag(i) != TokenKind.TK_KW_FN: continue
        if i + 1 >= n or toks.get_tag(i + 1) != TokenKind.TK_IDENT: continue
        // A `c facade` row (`fn rt_libc_read` under a domain, no parameter
        // list) describes a foreign extern; it is not a definition.
        if i + 2 >= n or toks.get_tag(i + 2) != TokenKind.TK_L_PAREN: continue
        let is_extern = i > 0 and toks.get_tag(i - 1) == TokenKind.TK_KW_EXTERN
        if is_extern != want_extern: continue
        let name = text.slice(toks.get_start(i + 1) as i64, toks.get_end(i + 1) as i64)
        if not (name.starts_with("with_") or name.starts_with("rt_")): continue

        var sig = "("
        var k = i + 2
        var depth = 0
        var after_colon = false
        var first_word = true
        var done = false
        while k < n and not done:
            let tag = toks.get_tag(k)
            if tag == TokenKind.TK_L_PAREN:
                depth = depth + 1
                if depth == 1:
                    k = k + 1
                    continue
            if tag == TokenKind.TK_R_PAREN:
                depth = depth - 1
                if depth == 0:
                    sig = sig ++ ")"
                    var j = k + 1
                    if j < n and toks.get_tag(j) == TokenKind.TK_ARROW:
                        j = j + 1
                        sig = sig ++ "->"
                        while j < n and not ends_return_type(toks.get_tag(j)):
                            sig = sig ++ text.slice(toks.get_start(j) as i64, toks.get_end(j) as i64)
                            j = j + 1
                    else:
                        let wi_ret = if wi_for_file.len() > 0: (wi_returns.get(f"{wi_for_file}|{name}") ?? "Unit") else: "Unit"
                        sig = sig ++ "->" ++ wi_ret
                    done = true
                    continue
            if depth == 1 and tag == TokenKind.TK_COMMA:
                after_colon = false
                first_word = true
                sig = sig ++ ","
                k = k + 1
                continue
            if depth == 1 and tag == TokenKind.TK_COLON:
                after_colon = true
                k = k + 1
                continue
            if after_colon:
                if not first_word: sig = sig ++ " "
                sig = sig ++ text.slice(toks.get_start(k) as i64, toks.get_end(k) as i64)
                first_word = false
            k = k + 1
        var pins = ""
        var b = i - 1
        while b >= 0 and (toks.get_tag(b) == TokenKind.TK_KW_EXTERN or toks.get_tag(b) == TokenKind.TK_KW_PUB or toks.get_tag(b) == TokenKind.TK_NEWLINE):
            b = b - 1
        while b >= 0 and toks.get_tag(b) == TokenKind.TK_R_BRACKET:
            var a = b
            while a > 0 and toks.get_tag(a) != TokenKind.TK_NEWLINE and not (toks.get_tag(a) == TokenKind.TK_AT and toks.get_tag(a + 1) == TokenKind.TK_L_BRACKET):
                a = a - 1
            if toks.get_tag(a) != TokenKind.TK_AT: break
            let attr = normalize_type_text(text.slice(toks.get_start(a) as i64, toks.get_end(b) as i64))
            if attr.starts_with("@[effect("): pins = attr
            b = a - 1
            while b >= 0 and toks.get_tag(b) == TokenKind.TK_NEWLINE:
                b = b - 1
        found.push(f"{name}|{expand_aliases(sig, aliases)}|{pins}|{path}:{line_of(text, toks.get_start(i))}")
    found

fn load_aliases(root: &str) -> List[str]:
    var out: List[str] = List.new()
    for p in list_files_text(root).split("\n"):
        if not p.ends_with(".w"): continue
        for line in (read_file(p) ?? "").split("\n"):
            if not line.starts_with("type "): continue
            let eq = line.find(" = ")
            if eq < 0: continue
            let alias = line.slice(5, eq as i64)
            let body = line.slice((eq + 3) as i64, line.len())
            out.push(f"{alias}|{normalize_type_text(body)}")
    out

fn normalize_type_text(body: &str) -> str:
    body.replace(" ", "")

fn expand_aliases(sig: &str, rt_aliases: &List[str]) -> str:
    var out = normalize_type_text(sig)
    for i in 0..rt_aliases.len():
        let rec = rt_aliases[i]
        let bar = rec.find("|")
        let alias = rec.slice(0, bar as i64)
        let body = rec.slice((bar + 1) as i64, rec.len())
        out = out.replace(alias, body)
    out

fn collect(root: &str, want_extern: bool, aliases: &List[str], wi_returns: &HashMap[str, str]) -> List[str]:
    var all: List[str] = List.new()
    for p in list_files_text(root).split("\n"):
        if not p.ends_with(".w"): continue
        for r in scan(p, want_extern, aliases, wi_returns):
            all.push(owned(r))
    all

fn field(rec: &str, k: i32) -> str:
    var i = 0
    for part in rec.split("|"):
        if i == k: return owned(part)
        i = i + 1
    ""

fn ret_of_sig(sig: &str) -> str:
    let arrow = sig.rfind("->")
    if arrow < 0: return "Unit"
    owned(sig.slice(arrow + 2, sig.len()))

fn map_c_return_type(c_ret: &str) -> str:
    if c_ret == "void": return "Unit"
    if c_ret == "int32_t": return "i32"
    if c_ret == "int64_t": return "i64"
    if c_ret == "uint32_t": return "u32"
    if c_ret == "uint64_t": return "u64"
    if c_ret == "with_str": return "str"
    if c_ret == "bool": return "bool"
    if c_ret == "double": return "f64"
    ""

fn audit_c_header(header_path: &str, defs: &List[str]) -> i32:
    let text = read_file(header_path) ?? ""
    if text.len() == 0: return 0
    var bad = 0
    var ln = 0
    for raw in text.split("\n"):
        ln += 1
        let line = raw.trim()
        if line.len() == 0 or line.starts_with("//") or line.starts_with("#") or line.starts_with("typedef"): continue
        let lp = line.find("(")
        if lp <= 0: continue
        let head = line.slice(0, lp).trim()
        let sp = head.rfind(" ")
        if sp <= 0: continue
        let c_ret = head.slice(0, sp).trim()
        let name = head.slice(sp + 1, head.len()).trim()
        if name.starts_with("*"): continue
        if not name.starts_with("with_"): continue
        if name.starts_with("with_panic"): continue
        let expected_ret = map_c_return_type(c_ret)
        if expected_ret.len() == 0: continue
        for di in 0..defs.len():
            if field(defs[di], 0) != name: continue
            let dret = ret_of_sig(field(defs[di], 1))
            if dret == "Never" and expected_ret == "Unit": continue
            if dret != expected_ret:
                print(f"{name}\n  def    ->{dret}   [{field(defs[di], 3)}]\n  header ->{expected_ret}   [{header_path}:{ln}]")
                bad += 1
                break
    bad

fn audit_cross_backend_returns(defs: &List[str]) -> i32:
    var first_ret: HashMap[str, str] = HashMap.new()
    var first_loc: HashMap[str, str] = HashMap.new()
    var reported: HashMap[str, i32] = HashMap.new()
    var bad = 0
    for di in 0..defs.len():
        let name = field(defs[di], 0)
        if name.starts_with("rt_libc_") or name.starts_with("with_fiber_coro_"): continue
        let dret = ret_of_sig(field(defs[di], 1))
        let dloc = field(defs[di], 3)
        match first_ret.get(name):
            Some(prev_ret) =>
                if prev_ret != dret and not reported.contains(name):
                    let ploc = first_loc.get(name) ?? ""
                    print(f"{name}\n  def1 ->{prev_ret}   [{ploc}]\n  def2 ->{dret}   [{dloc}]")
                    reported.insert(name, 1)
                    bad += 1
            None =>
                first_ret.insert(name, dret)
                first_loc.insert(name, dloc)
    bad

let aliases = load_aliases("rt")
let wi_returns = load_wi_returns()
let defs = collect("rt", false, aliases, wi_returns)
var decls: List[str] = List.new()
var roots: List[str] = List.new()
roots.push("rt")
roots.push("lib/std")
roots.push("src")
roots.push("tools")
roots.push("test")
for ri in 0..roots.len():
    for r in collect(roots[ri], true, aliases, wi_returns):
        decls.push(owned(r))

var bad = 0
for ei in 0..decls.len():
    let ename = field(decls[ei], 0)
    let esig = field(decls[ei], 1)
    let epins = field(decls[ei], 2)
    for di in 0..defs.len():
        if field(defs[di], 0) != ename: continue
        let dsig = field(defs[di], 1)
        let dpins = field(defs[di], 2)
        if esig == dsig and epins == dpins: continue
        print(f"{ename}\n  def  {dpins} {dsig}   [{field(defs[di], 3)}]\n  decl {epins} {esig}   [{field(decls[ei], 3)}]")
        bad = bad + 1
        break
bad = bad + audit_c_header("runtime/with_runtime.h", defs)
bad = bad + audit_cross_backend_returns(defs)
print(f"-- {bad} divergent decls / {defs.len()} rt defs / {decls.len()} extern with_*/rt_* decls")
exit_code(if bad > 0: 1 else: 0)
