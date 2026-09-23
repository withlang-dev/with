// tools/move_audit.w — the move-checker verdict matrix (the compile-time
// analog of tools/drop_audit.w).
//
// The move checker is a pile of hand-written dataflow transfer functions —
// one per control-flow edge (if-join, match-join, loop fall-through back-edge,
// `continue` back-edge, `break` exit, early-return divergence) — and nothing
// forces them to encode the SAME "moved across this edge?" rule. #696 was
// exactly this: the `continue` back-edge check (check_loop_continue_carried_move)
// fired on "MOVED now" alone while the fall-through check
// (finalize_loop_move_state) correctly required "LIVE at entry AND MOVED now".
// A value moved BEFORE the loop was wrongly reported as moved INSIDE it. The
// #613 diagnostic shipped with zero tests, so the divergence sat latent.
//
// This tool enumerates (edge × move-timing × value-shape) as small programs,
// each with a GROUND-TRUTH expected verdict — does the move diagnostic fire or
// not — and checks the candidate compiler against it. A drifted transfer
// function makes some cell disagree with its expectation, so the whole class
// self-identifies. With a baseline compiler, cells are also flagged when the
// candidate's verdict differs from the baseline's.
//
//   with run tools/move_audit.w <candidate-with> [baseline-with]
//   with build :move-audit          # candidate=out/release/bin/with,
//                                   # baseline=installed `with`
//
// Verdicts: OK (compiles) | MOVE-ERR (move diagnostic) | FIELD-ERR (an
// implicit field move, §2.2 D32 / D22 §13.6) | OTHER-ERR (a different compile
// error — the cell is malformed, fix it).
//
// Value shapes:
//   drop  — a Drop struct: single-ownership NOW, flip-independent. These cells
//           carry the real move-checker ground truth and would have caught #696
//           the day #613 landed.
//   vec   — Vec[i32] (POD elements): copy-on-move TODAY (#607/A5), so its moves
//           never invalidate and true-positive cells EXPECT OK. The #691 wide
//           flip makes Vec single-owner; when it lands, flip the vec
//           true-positive expectations to MOVE-ERR (mirrors drop_audit's
//           POD-EXPECT-LEAK cells). Until then these pin that the flip has NOT
//           silently half-landed.
//
// Run BEFORE and AFTER any change to move/borrow checking, branch-merge, loop
// back-edge handling, or type_needs_drop.

use std.process

extern fn with_exec_argv_capture(argv: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32) -> i32
extern fn with_fs_read_file(path: &str) -> str
extern fn with_fs_write_file(path: &str, data: &str) -> i32
extern fn with_fs_mkdir_p(path: &str) -> i32

fn exec_capture(argv: &str, outp: &str, errp: &str, timeout: i32) -> i32:
    unsafe:
        with_exec_argv_capture(argv, outp, errp, timeout)

fn read_file(path: &str) -> str:
    unsafe:
        with_fs_read_file(path)

fn write_file(path: &str, data: &str) -> i32:
    unsafe:
        with_fs_write_file(path, data)

fn mkdirs(path: &str) -> i32:
    unsafe:
        with_fs_mkdir_p(path)

fn argv3(a: &str, b: &str, c: &str) -> str:
    a ++ "\0" ++ b ++ "\0" ++ c ++ "\0"

// ── Shapes ────────────────────────────────────────────────────────────────
// Each shape supplies a prelude (type + consume fn + mk fn), the spelled type,
// and the make-expression. `consume(move x)` invalidates `x` for the `drop`
// shape; for `vec` it is a non-destructive copy today.

fn shape_prelude(shape: &str) -> str:
    if shape == "drop":
        return "type D { id: i32 }\n" ++
            "impl Drop for D:\n    fn drop(move self: Self): ()\n" ++
            "fn consume(d: D): ()\n" ++
            "fn mk() -> D: D { id: 1 }\n"
    if shape == "vec":
        return "fn consume(v: Vec[i32]): ()\n" ++
            "fn mk() -> Vec[i32]:\n    var v: Vec[i32] = Vec.new()\n    v.push(1)\n    v\n"
    ""

fn shape_ty(shape: &str) -> str:
    if shape == "vec": return "Vec[i32]"
    if shape == "str": return "str"
    "D"

// ── Scenario builders ─────────────────────────────────────────────────────
// Every scenario is a full program. `f` exercises one edge/timing; `main`
// just calls it. The move checker's verdict on `f` is what we classify.

fn wrap(shape: str, body: str) -> str:
    shape_prelude(shape) ++ body ++ "fn main:\n    f(3)\n    print(\"ok\")\n"

// moved BEFORE the loop, never touched inside — the loop's back-edges must not
// flag it. WITH a `continue` (the #696 shape).
fn sc_before_loop_continue(shape: str) -> str:
    wrap(shape,
        "fn f(n: i32):\n" ++
        "    let x: " ++ shape_ty(shape) ++ " = mk()\n" ++
        "    consume(move x)\n" ++
        "    for i in 0..n:\n" ++
        "        if i > 0:\n" ++
        "            continue\n" ++
        "        let _k = 0\n")

// moved BEFORE the loop, plain body (fall-through back-edge only).
fn sc_before_loop_plain(shape: str) -> str:
    wrap(shape,
        "fn f(n: i32):\n" ++
        "    let x: " ++ shape_ty(shape) ++ " = mk()\n" ++
        "    consume(move x)\n" ++
        "    for i in 0..n:\n" ++
        "        let _k = i\n")

// moved INSIDE the loop on the path that reaches `continue`; LIVE at entry.
// A genuine loop-carried use-after-move.
fn sc_inside_continue(shape: str) -> str:
    wrap(shape,
        "fn f(n: i32):\n" ++
        "    var x: " ++ shape_ty(shape) ++ " = mk()\n" ++
        "    for i in 0..n:\n" ++
        "        if i > 0:\n" ++
        "            consume(move x)\n" ++
        "            continue\n")

// moved INSIDE the loop, fall-through back-edge; LIVE at entry.
fn sc_inside_fallthrough(shape: str) -> str:
    wrap(shape,
        "fn f(n: i32):\n" ++
        "    var x: " ++ shape_ty(shape) ++ " = mk()\n" ++
        "    for i in 0..n:\n" ++
        "        consume(move x)\n")

// moved INSIDE the loop then REINITIALIZED before the back-edge — sound.
fn sc_inside_then_reinit(shape: str) -> str:
    wrap(shape,
        "fn f(n: i32):\n" ++
        "    var x: " ++ shape_ty(shape) ++ " = mk()\n" ++
        "    for i in 0..n:\n" ++
        "        consume(move x)\n" ++
        "        x = mk()\n")

// moved INSIDE the loop then BREAK on the same path — no back-edge carries it.
fn sc_inside_then_break(shape: str) -> str:
    wrap(shape,
        "fn f(n: i32):\n" ++
        "    var x: " ++ shape_ty(shape) ++ " = mk()\n" ++
        "    for i in 0..n:\n" ++
        "        consume(move x)\n" ++
        "        break\n")

// moved BEFORE the loop and USED inside — a plain use-after-move.
fn sc_before_used_inside(shape: str) -> str:
    wrap(shape,
        "fn f(n: i32):\n" ++
        "    let x: " ++ shape_ty(shape) ++ " = mk()\n" ++
        "    consume(move x)\n" ++
        "    for i in 0..n:\n" ++
        "        consume(move x)\n")

// while-loop variant of the #696 shape (finalize_loop_move_state has_condition_exit=1,
// and the same continue back-edge path).
fn sc_before_while_continue(shape: str) -> str:
    wrap(shape,
        "fn f(n: i32):\n" ++
        "    let x: " ++ shape_ty(shape) ++ " = mk()\n" ++
        "    consume(move x)\n" ++
        "    var i = 0\n" ++
        "    while i < n:\n" ++
        "        i = i + 1\n" ++
        "        if i > 1:\n" ++
        "            continue\n" ++
        "        let _k = 0\n")

// loop{} variant of the #696 shape (has_condition_exit=0; exits only via break).
fn sc_before_loopkw_continue(shape: str) -> str:
    wrap(shape,
        "fn f(n: i32):\n" ++
        "    let x: " ++ shape_ty(shape) ++ " = mk()\n" ++
        "    consume(move x)\n" ++
        "    var i = 0\n" ++
        "    loop:\n" ++
        "        if i >= n:\n" ++
        "            break\n" ++
        "        i = i + 1\n" ++
        "        if i > 1:\n" ++
        "            continue\n" ++
        "        let _k = 0\n")

// moved on a RETURNING (divergent) branch; the fall-through still owns it (#695).
fn sc_divergent_branch(shape: str) -> str:
    shape_prelude(shape) ++
        "fn f(n: i32) -> " ++ shape_ty(shape) ++ ":\n" ++
        "    let x: " ++ shape_ty(shape) ++ " = mk()\n" ++
        "    if n > 0:\n" ++
        "        return x\n" ++
        "    x\n" ++
        "fn main:\n    let _r = f(3)\n    print(\"ok\")\n"

// moved in a let-else's else branch, which diverges (§9.7): the path that
// continues past the let-else still owns it (#1383). `exit` is how the else
// branch leaves: return, or break/continue out of the enclosing loop.
fn sc_let_else_else_move(shape: &str, exit: &str) -> str:
    wrap(shape.clone(),
        "fn pick(n: i32) -> Option[i32]:\n" ++
        "    if n > 1: return None\n" ++
        "    Some(n)\n" ++
        "fn f(n: i32):\n" ++
        "    for i in 0..n:\n" ++
        "        let x: " ++ shape_ty(shape) ++ " = mk()\n" ++
        "        let Some(_v) = pick(i) else:\n" ++
        "            consume(move x)\n" ++
        "            " ++ exit ++ "\n" ++
        "        consume(move x)\n")

// the same move, then a use on the continuing path AFTER a second consume —
// a genuine use-after-move the fix must still report.
fn sc_let_else_else_move_then_reuse(shape: &str) -> str:
    wrap(shape.clone(),
        "fn pick(n: i32) -> Option[i32]:\n" ++
        "    if n > 1: return None\n" ++
        "    Some(n)\n" ++
        "fn f(n: i32):\n" ++
        "    let x: " ++ shape_ty(shape) ++ " = mk()\n" ++
        "    let Some(_v) = pick(n) else:\n" ++
        "        consume(move x)\n" ++
        "        return\n" ++
        "    consume(move x)\n" ++
        "    consume(move x)\n")

// ── Field values reaching an owned result (#1395, §2.2 D32, §3.8 join) ─────
// A field never moves out implicitly. `let x = base.p` binds a view (OK);
// every other position whose value becomes an owned result — an `if`/`match`
// arm joined with an owned arm, a `??` operand, a block tail, a `break`
// value, an inferred-return tail, a consuming argument — is an implicit field
// move and must fail at the move site (FIELD-ERR), on every base: a `mut fn`
// receiver, a read `fn` receiver, an owned local. #1395: the arms escaped the
// D32 funnel; a `mut fn` blanked the field and a read `fn` double-freed it.
// `.clone()` keeps the owner whole (OK); `move` vacates through a mutable
// path (OK) and is refused through a read path (FIELD-ERR's sibling, the
// read-path vacate error, classified OTHER-ERR — not asserted here).

fn field_prelude(shape: &str) -> str:
    var pre = shape_prelude(shape)
    if shape == "str":
        pre = "fn consume(s: str): ()\nfn mk() -> str: \"ab\" ++ \"c\"\n"
    pre ++ "type H { p: " ++ shape_ty(shape) ++ ", o: Option[" ++ shape_ty(shape) ++ "] }\n" ++
        "fn mkh() -> H: H { p: mk(), o: Some(mk()) }\n"

fn field_form(form: &str, b: &str) -> str:
    if form == "plain": return "let _x = " ++ b ++ ".p\n"
    if form == "if": return "let _x = if c > 0: " ++ b ++ ".p else: mk()\n"
    if form == "match": return "let _x = match c:\n            0 => mk()\n            _ => " ++ b ++ ".p\n"
    if form == "coalesce": return "let _x = " ++ b ++ ".o ?? mk()\n"
    if form == "block": return "let _x = { let _n = c\n            " ++ b ++ ".p }\n"
    if form == "break": return "let _x = loop:\n            break " ++ b ++ ".p\n"
    if form == "arg": return "consume(if c > 0: " ++ b ++ ".p else: mk())\n"
    if form == "clone": return "let _x = if c > 0: " ++ b ++ ".p.clone() else: mk()\n"
    if form == "move": return "let _x = if c > 0: move " ++ b ++ ".p else: mk()\n"
    // #1408 (§3.8 join rule 3): every arm a field place, nothing owned —
    // the join is a view of the places, no field moves.
    if form == "ifview": return "let _x = if c > 0: " ++ b ++ ".p else: " ++ b ++ ".p\n"
    if form == "matchview": return "let _x = match c:\n            0 => " ++ b ++ ".p\n            _ => " ++ b ++ ".p\n"
    if form == "blockview": return "let _x = if c > 0: { let _n = c\n            " ++ b ++ ".p } else: " ++ b ++ ".p\n"
    // ...but an owned demand on that join (a consuming argument) still moves
    // the fields: rule 5, D32.
    if form == "viewarg": return "consume(if c > 0: " ++ b ++ ".p else: " ++ b ++ ".p)\n"
    ""

// base ∈ { mutrecv, readrecv, local }; form "retinfer" is an unannotated
// method/fn whose tail is the join.
fn sc_field(shape: &str, base: &str, form: &str) -> str:
    let b = if base == "local": "h" else: "self"
    var body = ""
    if form == "retinfer":
        body = "    if c > 0: " ++ b ++ ".p else: mk()\n"
    else:
        body = "    " ++ field_form(form, b)
    if base == "local":
        return field_prelude(shape) ++ "fn f(c: i32):\n    var h = mkh()\n" ++ body ++
            "fn main:\n    let _r = f(3)\n    print(\"ok\")\n"
    let mode = if base == "mutrecv": "mut fn" else: "fn"
    field_prelude(shape) ++ "impl H:\n    " ++ mode ++ " f(c: i32):\n    " ++ body.replace("\n    ", "\n        ") ++
        "fn main:\n    var h = mkh()\n    let _r = h.f(3)\n    print(\"ok\")\n"

// ── A cell: name, source, expected verdict ────────────────────────────────
// verdict ∈ { "OK", "MOVE-ERR", "FIELD-ERR" }.
type Cell { name: str, source: str, expect: str }

fn build_cells() -> Vec[Cell]:
    var cells: Vec[Cell] = Vec.new()

    // drop shape: single-ownership NOW → stable ground truth (flip-independent).
    cells.push(Cell { name: "before_loop_continue/drop", source: sc_before_loop_continue("drop"), expect: "OK" })       // #696
    cells.push(Cell { name: "before_loop_plain/drop", source: sc_before_loop_plain("drop"), expect: "OK" })
    cells.push(Cell { name: "inside_continue/drop", source: sc_inside_continue("drop"), expect: "MOVE-ERR" })
    cells.push(Cell { name: "inside_fallthrough/drop", source: sc_inside_fallthrough("drop"), expect: "MOVE-ERR" })
    cells.push(Cell { name: "inside_then_reinit/drop", source: sc_inside_then_reinit("drop"), expect: "OK" })
    cells.push(Cell { name: "inside_then_break/drop", source: sc_inside_then_break("drop"), expect: "OK" })
    cells.push(Cell { name: "before_used_inside/drop", source: sc_before_used_inside("drop"), expect: "MOVE-ERR" })
    cells.push(Cell { name: "before_while_continue/drop", source: sc_before_while_continue("drop"), expect: "OK" })    // #696 (while)
    cells.push(Cell { name: "before_loopkw_continue/drop", source: sc_before_loopkw_continue("drop"), expect: "OK" }) // #696 (loop)
    cells.push(Cell { name: "divergent_branch/drop", source: sc_divergent_branch("drop"), expect: "OK" })             // #695

    // vec shape: #691 made every Vec single-owner, so the LOOP-CARRIED checks
    // (the cells the old copy-on-move #607 world reported OK) now demand
    // MOVE-ERR — this is the pre-planned [FLIP:->ERR] pin flip. An explicit
    // `move x` invalidates the BINDING regardless of shape/needs_drop, so a
    // plain use-after-move (before_used_inside) was MOVE-ERR either way.
    cells.push(Cell { name: "before_loop_continue/vec", source: sc_before_loop_continue("vec"), expect: "OK" })
    cells.push(Cell { name: "inside_continue/vec[FLIPPED:#691]", source: sc_inside_continue("vec"), expect: "MOVE-ERR" })
    cells.push(Cell { name: "inside_fallthrough/vec[FLIPPED:#691]", source: sc_inside_fallthrough("vec"), expect: "MOVE-ERR" })
    cells.push(Cell { name: "before_used_inside/vec", source: sc_before_used_inside("vec"), expect: "MOVE-ERR" })
    cells.push(Cell { name: "divergent_branch/vec", source: sc_divergent_branch("vec"), expect: "OK" })

    // #1383: a move in a let-else's diverging else branch stays on that path.
    for shape in ["drop", "vec"]:
        for exit in ["return", "break", "continue"]:
            cells.push(Cell { name: f"let_else_else_move_{exit}/{shape}", source: sc_let_else_else_move(shape, exit), expect: "OK" })
        cells.push(Cell { name: f"let_else_else_move_then_reuse/{shape}", source: sc_let_else_else_move_then_reuse(shape), expect: "MOVE-ERR" })

    // #1395: a field value reaching an owned result, on every base.
    for shape in ["str", "vec"]:
        for base in ["mutrecv", "readrecv", "local"]:
            for form in ["plain", "if", "match", "coalesce", "block", "break", "arg", "retinfer", "clone", "move", "ifview", "matchview", "blockview", "viewarg"]:
                if form == "move" and base == "readrecv":
                    continue
                let expect = if form == "plain" or form == "clone" or form == "move" or form == "ifview" or form == "matchview" or form == "blockview": "OK" else: "FIELD-ERR"
                cells.push(Cell { name: f"field_{form}/{base}/{shape}", source: sc_field(shape, base, form), expect })
    cells

// ── Runner ─────────────────────────────────────────────────────────────────

fn find_sub(s: &str, sub: &str) -> i64:
    let n = s.len()
    let m = sub.len()
    if m == 0:
        return 0
    var i: i64 = 0
    while i + m <= n:
        if s.slice(i, i + m) == sub:
            return i
        i = i + 1
    0 - 1

fn classify(with_bin: &str, dir: &str, idx: i32, source: &str) -> str:
    let path = dir ++ f"/cell_{idx}.w"
    let _ = write_file(path, source)
    let outp = dir ++ f"/cell_{idx}.out"
    let errp = dir ++ f"/cell_{idx}.err"
    let _rc = exec_capture(argv3(with_bin, "check", path), outp, errp, 60000)
    let err = read_file(errp)
    if find_sub(err, "error:") < 0:
        return "OK"
    // §2.2 D32 / D22 §13.6: an implicit field move, or one through a borrow.
    if find_sub(err, "a field never moves out implicitly") >= 0 or find_sub(err, "non-Copy field through a borrow") >= 0:
        return "FIELD-ERR"
    // A move-checker error mentions a moved value or a partial move.
    if find_sub(err, "moved") >= 0 or find_sub(err, "partial move") >= 0:
        return "MOVE-ERR"
    "OTHER-ERR"

fn main:
    let argv = args()
    if argv.len() < 2:
        eprint("usage: with run tools/move_audit.w <candidate-with> [baseline-with]")
        exit_code(2)
    let candidate = argv.get(1)
    // BOOTSTRAP INTERIM: materialize the argv view out of the ""-join (#762).
    let baseline = if argv.len() as i32 >= 3: argv.get(2) ++ "" else: ""
    let dir = "/tmp/move-audit-cells"
    let _ = mkdirs(dir)
    let cells = build_cells()
    var failures = 0
    var regressions = 0
    print("cell\texpect\tcandidate\tverdict" ++ (if baseline.len() > 0: "\tbaseline" else: ""))
    for i in 0..cells.len() as i32:
        let c = cells[i]
        let cv = classify(candidate, dir, i, c.source)
        let ok = cv == c.expect
        if not ok:
            failures = failures + 1
        var row = c.name ++ "\t" ++ c.expect ++ "\t" ++ cv ++ "\t" ++ (if ok: "pass" else: "FAIL")
        if baseline.len() > 0:
            let bv = classify(baseline, dir, i, c.source)
            if bv != cv:
                regressions = regressions + 1
            row = row ++ "\t" ++ bv ++ (if bv != cv: " (DIFF)" else: "")
        print(row)
    print(f"move-audit: {cells.len() as i32} cells, {failures} vs-expected FAIL, {regressions} candidate-vs-baseline DIFF")
    if failures > 0:
        exit_code(1)
    exit_code(0)
