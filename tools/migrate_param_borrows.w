// #747: rewrite read-only plain `str` fn params to `&str` (D5: observers
// borrow; auto-referencing keeps every call site spelled identically).
// Token-accurate via the compiler's own Lexer — no regex, no line hacks.
//
//   with run tools/migrate_param_borrows.w [--apply] <denylist> <file.w>...
//
// The denylist file holds `fn_name<TAB>param_name` pairs that must KEEP
// ownership (consumers). The driver loop grows it from the flipped
// checker's body errors until fixpoint. Dry-run prints planned edits.
use std.process
use Lexer
use Token

extern fn with_fs_read_file(path: &str) -> str
extern fn with_fs_write_file(path: &str, data: &str) -> i32
extern fn with_str_clone_ref(s: &str) -> str

fn read_file(path: &str): unsafe { with_fs_read_file(path) }
fn write_file(path: &str, data: &str): unsafe { with_fs_write_file(path, data) }
fn owned_text(s: &str): unsafe { with_str_clone_ref(s) }

fn deny_key(fn_name: &str, param: &str) -> str: fn_name ++ "\t" ++ param

fn main -> i32:
    let argv = args()
    var apply = false
    var deny_path = ""
    var files: Vec[str] = Vec.new()
    for i in 1..argv.len():
        let a = argv.get(i)
        if a == "--apply": apply = true
        else if deny_path.len() == 0: deny_path = owned_text(a)
        else: files.push(owned_text(a))
    if files.len() == 0:
        eprint("usage: migrate_param_borrows [--apply] <denylist> <file.w>...")
        return 2
    var denied: Vec[str] = Vec.new()
    for line in read_file(deny_path).split("\n"):
        if line.len() > 0: denied.push(owned_text(line))
    var total = 0
    for fi in 0..files.len():
        let path = files.get(fi)
        let text = read_file(path)
        if text.len() == 0: continue
        var lexer = Lexer.init(text, 0)
        let tokens = lexer.tokenize()
        let n = tokens.len()
        // Collect insertion offsets (byte positions where "&" goes).
        var offsets: Vec[i32] = Vec.new()
        var labels: Vec[str] = Vec.new()
        var i = 0
        while i < n:
            if tokens.get_tag(i) != TokenKind.TK_KW_FN:
                i = i + 1
                continue
            // extern fns are ABI contracts — never rewrite their params
            // (`extern fn f` and `extern "C" fn f` forms).
            if i > 0 and tokens.get_tag(i - 1) == TokenKind.TK_KW_EXTERN:
                i = i + 1
                continue
            if i > 1 and tokens.get_tag(i - 1) == TokenKind.TK_STRING_LIT and tokens.get_tag(i - 2) == TokenKind.TK_KW_EXTERN:
                i = i + 1
                continue
            // fn NAME[.METHOD] [ [generics] ] ( params )
            var k = i + 1
            if k >= n or tokens.get_tag(k) != TokenKind.TK_IDENT:
                i = i + 1
                continue
            var fn_name = text.slice(tokens.get_start(k) as i64, tokens.get_end(k) as i64)
            k = k + 1
            while k + 1 < n and tokens.get_tag(k) == TokenKind.TK_DOT and tokens.get_tag(k + 1) == TokenKind.TK_IDENT:
                fn_name = fn_name ++ "." ++ text.slice(tokens.get_start(k + 1) as i64, tokens.get_end(k + 1) as i64)
                k = k + 2
            if k < n and tokens.get_tag(k) == TokenKind.TK_L_BRACKET:
                var bd = 0
                while k < n:
                    let bt = tokens.get_tag(k)
                    if bt == TokenKind.TK_L_BRACKET: bd = bd + 1
                    if bt == TokenKind.TK_R_BRACKET:
                        bd = bd - 1
                        if bd == 0:
                            k = k + 1
                            break
                    k = k + 1
            if k >= n or tokens.get_tag(k) != TokenKind.TK_L_PAREN:
                i = k
                continue
            // Walk params at paren depth 1.
            var depth = 1
            k = k + 1
            var at_param_start = true
            while k < n and depth > 0:
                let t = tokens.get_tag(k)
                if t == TokenKind.TK_L_PAREN or t == TokenKind.TK_L_BRACKET: depth = depth + 1
                else if t == TokenKind.TK_R_PAREN or t == TokenKind.TK_R_BRACKET:
                    depth = depth - 1
                else if depth == 1 and t == TokenKind.TK_COMMA:
                    at_param_start = true
                    k = k + 1
                    continue
                if depth == 1 and at_param_start and t == TokenKind.TK_IDENT:
                    // NAME : TYPE — rewrite only when TYPE is exactly `str`
                    // followed by , ) or = (skips *str, &str, Vec[str], self).
                    let pname = text.slice(tokens.get_start(k) as i64, tokens.get_end(k) as i64)
                    if k + 2 < n and tokens.get_tag(k + 1) == TokenKind.TK_COLON and tokens.get_tag(k + 2) == TokenKind.TK_IDENT and text.slice(tokens.get_start(k + 2) as i64, tokens.get_end(k + 2) as i64) == "str":
                        let after = if k + 3 < n: tokens.get_tag(k + 3) else: TokenKind.TK_R_PAREN
                        if after == TokenKind.TK_COMMA or after == TokenKind.TK_R_PAREN or after == TokenKind.TK_EQ:
                            var deny = false
                            let key = deny_key(fn_name, pname)
                            for di in 0..denied.len():
                                if denied.get(di) == key:
                                    deny = true
                                    break
                            if not deny:
                                offsets.push(tokens.get_start(k + 2))
                                labels.push(fn_name ++ "(" ++ pname ++ ")")
                    at_param_start = false
                else if depth == 1 and t != TokenKind.TK_COMMA:
                    at_param_start = false
                k = k + 1
            i = k
        if offsets.len() == 0: continue
        total = total + offsets.len() as i32
        if not apply:
            for oi in 0..offsets.len():
                print(path ++ ": " ++ labels.get(oi))
            continue
        // Apply back-to-front so earlier offsets stay valid.
        var out = owned_text(text)
        var oi = offsets.len() as i32 - 1
        while oi >= 0:
            let at = offsets[oi] as i64
            out = out.slice(0, at) ++ "&" ++ out.slice(at, out.len())
            oi = oi - 1
        if write_file(path, out) != 0:
            eprint("migrate-param-borrows: cannot write " ++ path)
            return 1
        print(f"{path}: {offsets.len() as i32} params borrowed")
    print(f"total: {total}")
    0
