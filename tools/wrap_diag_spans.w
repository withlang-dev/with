// #747 Phase C step 2: wrap flipped-checker diagnostic spans in
// owned_text(...) by byte edit. The flipped stage1 owns the error
// decision and the exact span; this tool only validates span shape and
// applies back-to-front source edits. Dry-run is the default.
//
//   out/bootstrap/bin/with-stage1 check src/main.w 2> diags.txt
//   with run tools/wrap_diag_spans.w [--apply] [--skip skips.txt] diags.txt
//   with run tools/wrap_diag_spans.w --finalize-existing diags.txt
//
// Handled kinds (clones are CORRECT under the flip; #748 view tokens
// recover the copies later):
//   1 wrong argument type in call to 'Vec.push'      (span = argument)
//   2 D22 §13.6 field-through-borrow — call argument (span = field read;
//     a span directly inside with_str_clone(...) renames the call to
//     with_str_clone_ref instead of double-cloning)
//   3 D22 §13.6 field-through-borrow — struct literal field
//   4 type mismatch in struct literal field (bare ident/field spans only)
//   5 type mismatch in assignment (wraps the RHS of `lhs = rhs`)
//   6 return type mismatch (bare ident/field spans only)
//
// The skip file lists `path:line:col` sites to leave alone (sites whose
// wrap broke the SEED gate build).
//
// Bootstrap note: no direct with_* extern decls here — this tool is built
// by whatever seed is current, so it must reach the runtime only through
// the prelude/std surface that seed embeds (self-consistent in both eras).
use std.process
use std.fs
use std.string.StringBuilder

type Site {
    path: str,
    line_no: i32,
    col: i32,
    span_len: i32,
    kind: i32,
}

type EditPlan {
    starts: Vec[i64],
    ends: Vec[i64],
    texts: Vec[str],
}

fn parse_int(text: &str) -> i32:
    if text.len() == 0: return -1
    var n = 0
    for i in 0..text.len() as i32:
        let b = text[i]
        if b < 48 or b > 57: return -1
        n = n * 10 + (b - 48)
    n

fn source_path(path: &str) -> str:
    let embedded = "<embedded-std>/"
    if path.starts_with(embedded): "lib/" ++ path.slice(embedded.len(), path.len()) else: path.slice(0, path.len())

fn owned_fn_name(path: &str) -> str:
    var start: i64 = 0
    var end = path.len()
    for i in 0..path.len():
        if path[i] == 47: start = i + 1
        if path[i] == 46: end = i
    path.slice(start, end).replace("-", "_") ++ "_owned_text"

fn classify(line: &str) -> i32:
    if line == "error: wrong argument type in call to 'Vec.push'": return 1
    if line.starts_with("error: cannot take ownership of a non-Copy field through a borrow"):
        if line.ends_with("— call argument"): return 2
        if line.ends_with("— struct literal field"): return 3
        // assignment / typed-let-binding spans cover just the borrowed
        // field read — the default wrap applies.
        if line.ends_with("— assignment"): return 8
        if line.ends_with("— typed let binding"): return 8
        return 0
    if line.starts_with("error: if would need to copy a `str`"): return 8
    if line == "error: type mismatch in binding": return 9
    if line == "error: type mismatch in struct literal field": return 4
    if line == "error: type mismatch in assignment": return 5
    if line == "error: return type mismatch": return 6
    if line.starts_with("error: wrong argument type in call to '"): return 7
    0

fn count_carets(line: &str) -> i32:
    var n = 0
    for i in 0..line.len() as i32:
        if line[i] == 94: n = n + 1
    n

fn is_ident_or_field(span: &str) -> bool:
    if span.len() == 0: return false
    for i in 0..span.len() as i32:
        let b = span[i]
        let ok = (b >= 48 and b <= 57) or (b >= 65 and b <= 90) or (b >= 97 and b <= 122) or b == 95 or b == 46
        if not ok: return false
    true

// byte index of the first plain ` = ` in the span, or -1.
fn find_assign_eq(span: &str) -> i64:
    var j: i64 = 0
    while j + 3 <= span.len():
        if span[j] == 32 and span[j + 1] == 61 and span[j + 2] == 32:
            var prev_ok = true
            if j > 0:
                let p = span[j - 1]
                if p == 61 or p == 33 or p == 60 or p == 62 or p == 43 or p == 45 or p == 42 or p == 47 or p == 37: prev_ok = false
            if prev_ok: return j
        j = j + 1
    -1

// preceding non-whitespace byte before offset, or 0.
fn prev_nonspace(text: &str, offset: i64) -> i32:
    var j = offset - 1
    while j >= 0:
        let b = text[j]
        if b != 32 and b != 9 and b != 10 and b != 13: return b
        j = j - 1
    0

fn kind_name(kind: i32) -> str:
    if kind == 1: return "vec-push"
    if kind == 2: return "d22-call-arg"
    if kind == 3: return "d22-struct-field"
    if kind == 4: return "struct-field-mismatch"
    if kind == 5: return "assignment"
    if kind == 7: return "wrong-arg"
    if kind == 8: return "borrowed-read"
    if kind == 9: return "typed-binding"
    "return"

fn load_skips(skip_path: &str) -> Vec[str]:
    var skips: Vec[str] = Vec.new()
    if skip_path.len() == 0: return skips
    let skip_text = read_file(skip_path ++ "") ?? ""
    let skip_lines = skip_text.split("\n")
    for i in 0..skip_lines.len() as i32:
        let s = skip_lines[i]
        if s.len() > 0: skips.push(s ++ "")
    skips

// Vec.push sites must carry a `has type &str` label when any type label is
// present at all; labels follow the caret line as `  = ` continuations.
fn push_label_ok(dlines: &Vec[str], caret_idx: i32) -> bool:
    var li = caret_idx + 1
    var label_seen = 0
    var label_ok = 0
    while (li as i64) < dlines.len():
        let extra = dlines[li]
        if not extra.starts_with("  = "): break
        if extra.contains("has type "):
            label_seen = 1
            if extra.contains("has type &str"): label_ok = 1
        li = li + 1
    label_seen == 0 or label_ok == 1

// A wrong-argument site is wrappable only when the argument is a &str
// meeting a consuming owned-str parameter (labels follow the caret line).
fn wrong_arg_label_ok(dlines: &Vec[str], caret_idx: i32) -> bool:
    var li = caret_idx + 1
    var borrowed_arg = 0
    var owned_param = 0
    while (li as i64) < dlines.len():
        let extra = dlines[li]
        if not extra.starts_with("  = "): break
        if extra.contains("has type &str"): borrowed_arg = 1
        if extra.ends_with("expects str"): owned_param = 1
        li = li + 1
    borrowed_arg == 1 and owned_param == 1

fn collect_sites(dlines: &Vec[str]) -> Vec[Site]:
    var sites: Vec[Site] = Vec.new()
    var seen_keys: Vec[str] = Vec.new()
    var i = 0
    while (i as i64) < dlines.len():
        let line = dlines[i]
        let kind = classify(line)
        if kind == 0:
            i = i + 1
            continue
        if (i as i64) + 3 >= dlines.len():
            break
        let loc = dlines.get(i as i64 + 1)
        let caret_line = dlines.get(i as i64 + 3)
        let caret_idx = i + 3
        i = i + 1
        if not loc.starts_with(" --> "):
            continue
        let loc_body = loc.slice(5, loc.len())
        let parts = loc_body.split(":")
        if parts.len() != 3:
            continue
        let path = source_path(parts.get(0))
        let line_no = parse_int(parts.get(1))
        let col = parse_int(parts.get(2))
        let span_len = count_carets(caret_line)
        if line_no <= 0 or col <= 0 or span_len <= 0:
            continue
        if kind == 1 and not push_label_ok(dlines, caret_idx):
            print("skip-label " ++ path ++ f":{line_no}:{col}")
            continue
        if kind == 7 and not wrong_arg_label_ok(dlines, caret_idx):
            print("skip-arg-label " ++ path ++ f":{line_no}:{col}")
            continue
        let key = path ++ f":{line_no}:{col}:{kind}"
        var dup = false
        for si in 0..seen_keys.len() as i32:
            if seen_keys[si] == key: dup = true
        if dup: continue
        seen_keys.push(key)
        sites.push(Site { path, line_no, col, span_len, kind })
    sites

fn unique_files(sites: &Vec[Site]) -> Vec[str]:
    var files: Vec[str] = Vec.new()
    for si in 0..sites.len() as i32:
        let p = sites[si].path
        var have = false
        for fi in 0..files.len() as i32:
            if files[fi] == p: have = true
        if not have: files.push(p ++ "")
    files

fn in_list(items: &Vec[str], key: &str) -> bool:
    for i in 0..items.len() as i32:
        if items[i] == key: return true
    false

fn line_offsets(flines: &Vec[str]) -> Vec[i64]:
    var offsets: Vec[i64] = Vec.new()
    var acc: i64 = 0
    for li in 0..flines.len() as i32:
        offsets.push(acc)
        acc = acc + flines[li].len() + 1
    offsets

fn plan_edits(path: &str, text: &str, sites: &Vec[Site], skips: &Vec[str]) -> EditPlan:
    let flines = text.split("\n")
    let offsets = line_offsets(&flines)
    var starts: Vec[i64] = Vec.new()
    var ends: Vec[i64] = Vec.new()
    var texts: Vec[str] = Vec.new()
    let clone_fn = owned_fn_name(path)
    for si in 0..sites.len() as i32:
        let site = sites[si]
        if site.path != path: continue
        let tag = path ++ f":{site.line_no}:{site.col}"
        if in_list(skips, tag):
            print("skip-list " ++ tag)
            continue
        if site.line_no as i64 > offsets.len():
            print("skip-line-range " ++ tag)
            continue
        let line_start = offsets.get(site.line_no as i64 - 1)
        let line_len = flines.get(site.line_no as i64 - 1).len()
        if site.col as i64 - 1 + site.span_len as i64 > line_len:
            print("skip-multiline " ++ tag ++ " kind=" ++ kind_name(site.kind))
            continue
        let start = line_start + site.col as i64 - 1
        let end = start + site.span_len as i64
        let span = text.slice(start, end)
        if span.len() == 0 or span[0] == 32 or span[span.len() - 1] == 32:
            print("skip-span-shape " ++ tag)
            continue
        var ed_start = start
        var ed_end = end
        var new_text = ""
        if site.kind == 2 and start >= 15 and text.slice(start - 15, start) == "with_str_clone(":
            // rename the consuming clone call instead of double-cloning
            ed_start = start - 15
            ed_end = start
            new_text = clone_fn ++ "("
        else if site.kind == 5 or site.kind == 9:
            let eq = find_assign_eq(span)
            if eq < 0:
                print("skip-no-assign " ++ tag)
                continue
            let rhs = span.slice(eq + 3, span.len())
            if rhs.starts_with("if ") or rhs.starts_with("match "):
                print("skip-branch-rhs " ++ tag)
                continue
            ed_start = start + eq + 3
            new_text = clone_fn ++ "(" ++ rhs ++ ")"
        else if site.kind == 6:
            // span may be a full `return <expr>` statement or a bare tail
            // expression; wrap just the expression. Any single-line span is
            // a complete expression (multiline spans were skipped above).
            var expr_off: i64 = 0
            if span.starts_with("return "):
                expr_off = 7
                while expr_off < span.len() and span[expr_off] == 32: expr_off = expr_off + 1
            let expr = span.slice(expr_off, span.len())
            if expr.starts_with("if ") or expr.starts_with("match ") or expr.len() == 0:
                print("skip-branch-span " ++ tag)
                continue
            ed_start = start + expr_off
            new_text = clone_fn ++ "(" ++ expr ++ ")"
        else:
            if site.kind == 4:
                if not is_ident_or_field(span):
                    print("skip-complex " ++ tag ++ " kind=" ++ kind_name(site.kind))
                    continue
            if site.kind == 3 or site.kind == 4:
                if prev_nonspace(text, start) != 58:
                    print("skip-shorthand " ++ tag)
                    continue
            if span.starts_with("if ") or span.starts_with("match "):
                print("skip-branch-span " ++ tag)
                continue
            new_text = clone_fn ++ "(" ++ span ++ ")"
        var overlap = false
        for ei in 0..starts.len() as i32:
            if ed_start < ends[ei] and starts[ei] < ed_end: overlap = true
        if overlap:
            print("skip-overlap " ++ tag)
            continue
        print("wrap " ++ tag ++ " kind=" ++ kind_name(site.kind) ++ " span='" ++ span ++ "'")
        starts.push(ed_start)
        ends.push(ed_end)
        texts.push(new_text)
    EditPlan { starts, ends, texts }

// seed workaround: the frozen seed miscompiles a Vec[str] element read
// feeding a concat that reassigns the accumulator in the same loop
// (#755 class); routing the edit through a helper keeps the IR valid.
fn splice(t: str, s: i64, e: i64, piece: &str) -> str:
    t.slice(0, s) ++ piece ++ t.slice(e, t.len())

fn apply_edits(text_in: str, plan: &EditPlan) -> str:
    var text = text_in
    let edit_count = plan.starts.len() as i32
    var order: Vec[i32] = Vec.new()
    for ei in 0..edit_count: order.push(ei)
    for a in 0..edit_count:
        var best = a
        for b in (a + 1)..edit_count:
            if plan.starts[order[b]] > plan.starts[order[best]]:
                best = b
        if best != a:
            // annotated: an unannotated binding is a live VIEW of the
            // element, and the first set below would change what it reads
            let tmp: i32 = order[a]
            order.slot(a as i64).set(order[best])
            order.slot(best as i64).set(tmp)
    for oi in 0..edit_count:
        let ei = order[oi] as i64
        let s = plan.starts.get(ei)
        let e = plan.ends.get(ei)
        text = splice(text, s, e, plan.texts.get(ei))
    text

fn ensure_decl(path: &str, text_in: str) -> str:
    let clone_fn = owned_fn_name(path)
    if text_in.contains("fn " ++ clone_fn ++ "(s: &str)"): return text_in
    let out_lines = text_in.split("\n")
    var insert_at: i64 = -1
    for li in 0..out_lines.len() as i32:
        if out_lines[li].starts_with("extern fn "):
            insert_at = li as i64
            break
    if insert_at < 0:
        var last_use: i64 = -1
        for li in 0..out_lines.len() as i32:
            if li >= 60: break
            if out_lines[li].starts_with("use "): last_use = li as i64
        insert_at = last_use + 1
    var sb = StringBuilder.new()
    for li in 0..out_lines.len() as i32:
        if li as i64 == insert_at:
            sb.push_str("fn " ++ clone_fn ++ "(s: &str): s ++ \"\"\n")
        sb.push_str(out_lines[li])
        if (li as i64) < out_lines.len() - 1: sb.push_str("\n")
    sb.to_str()

fn finalize_existing(path: &str) -> i32:
    var text = read_file(path ++ "") ?? ""
    if text.len() == 0: return -1
    let clone_fn = owned_fn_name(path)
    let prefix = clone_fn.slice(0, clone_fn.len() - 11)
    let doubled = prefix ++ "_" ++ clone_fn
    text = text.replace("fn " ++ doubled ++ "(s: &str): unsafe { with_str_clone_ref(s) }\n", "")
    text = text.replace(doubled ++ "(", clone_fn ++ "(")
    if text.contains("fn owned_text(s: &str)"):
        text = text.replace("owned_text(", clone_fn ++ "(")
    text = text.replace("fn " ++ clone_fn ++ "(s: &str): unsafe { with_str_clone_ref(s) }", "fn " ++ clone_fn ++ "(s: &str): s ++ \"\"")
    text = text.replace("extern fn with_str_clone_ref(s: &str) -> str\n", "")
    text = ensure_decl(path, text)
    if write_file(path ++ "", text) != 0: return -1
    print("finalized " ++ path)
    0

fn process_file(path: &str, sites: &Vec[Site], skips: &Vec[str], apply: i32) -> i32:
    var text = read_file(path ++ "") ?? ""
    if text.len() == 0:
        print("wrap-diag-spans: could not read source " ++ path)
        return -1
    let plan = plan_edits(path, text, sites, skips)
    let edit_count = plan.starts.len() as i32
    if edit_count == 0 or apply == 0: return edit_count
    text = apply_edits(text, &plan)
    text = ensure_decl(path, text)
    if write_file(path ++ "", text) != 0:
        print("wrap-diag-spans: write failed: " ++ path)
        return -1
    print("wrote " ++ path)
    edit_count

fn main -> i32:
    let argv = args()
    var apply = 0
    var finalize = 0
    var diag_path = ""
    var skip_path = ""
    var ai: i64 = 1
    while ai < argv.len():
        let arg = argv.get(ai)
        if arg == "--apply":
            apply = 1
        else if arg == "--finalize-existing":
            finalize = 1
        else if arg == "--skip":
            ai = ai + 1
            if ai >= argv.len():
                print("wrap-diag-spans: --skip needs a file argument")
                return 1
            skip_path = argv.get(ai) ++ ""
        else:
            diag_path = argv.get(ai) ++ ""
        ai = ai + 1
    if diag_path.len() == 0:
        print("usage: wrap_diag_spans [--apply] [--skip skips.txt] diags.txt")
        return 1
    let skips = load_skips(skip_path)
    let diag_text = read_file(diag_path ++ "") ?? ""
    if diag_text.len() == 0:
        print("wrap-diag-spans: could not read " ++ diag_path)
        return 1
    let dlines = diag_text.split("\n")
    let sites = collect_sites(&dlines)
    let site_count = sites.len()
    print(f"sites collected: {site_count}")
    let files = unique_files(&sites)
    if finalize == 1:
        for fi in 0..files.len() as i32:
            if finalize_existing(files[fi]) != 0: return 1
        return 0
    var total = 0
    for fi in 0..files.len() as i32:
        let n = process_file(files[fi], &sites, &skips, apply)
        if n < 0: return 1
        total = total + n
    print(f"planned/applied {total} edits")
    if apply == 0: print("dry run: re-run with --apply to write")
    0
