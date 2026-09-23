// tools/drop_audit.w — the drop-exactly-once audit matrix (repo-committed
// successor to the lost .claude/skills/drop-audit/audit.py, rewritten in
// With per the no-foreign-tooling rule).
//
// Generates a curated cell matrix over (value shape × ownership op ×
// receiver mode × control flow), runs every cell under the native debug
// allocator, and classifies verdicts. With a baseline compiler, a cell is a
// REGRESSION iff the candidate's verdict differs from the baseline's and
// the candidate does not PASS — so drop-scheduling changes self-identify;
// a cell the baseline could not even run and the candidate passes is FIXED
// (printed, never red: the baseline is the older seed). Without a
// baseline, verdicts compare against each cell's EXPECTED column only.
//
//   with run tools/drop_audit.w <candidate-with> [baseline-with]
//   with build :drop-audit          # candidate=out/release/bin/with,
//                                   # baseline=installed `with`
//
// Verdicts: PASS | LEAK | DOUBLE-FREE | VALUE-FAIL | COMPILE-FAIL | RUN-FAIL.
// POD-container cells expect CLEAN allocator verdicts (#691/D18: every Vec
// frees its buffer at scope exit and on reassignment).
// Run BEFORE and AFTER any change to drop scheduling, ownership lowering,
// or receiver modes (CLAUDE.md gate).

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

fn argv4(a: &str, b: &str, c: &str, d: &str) -> str:
    a ++ "\0" ++ b ++ "\0" ++ c ++ "\0" ++ d ++ "\0"

// ── The counted resource every cell drops ────────────────────────────────
// R carries a real allocation (over/under-drop shows up as allocator leak or
// double-free) and bumps *slot by its id on drop (value-level exactly-once).

fn resource_prelude():
    // Probes are user programs: allocate through std.mem. Redeclaring the
    // private runtime allocator here replaces imported signatures and can
    // break unrelated prelude code before the drop checks ever run.
    // D29 (#750): generated probes carry their imports — print_i32 and the
    // Box/Rc shape cells' names are import-gated under the §18.2 prelude.
    "use std.builtins.print_i32\n" ++
    "use std.box\n" ++
    "use std.rc\n" ++
    "use std.mem.alloc\n" ++
    "use std.mem.free_mem\n" ++
    "type R { id: i32, ptr: *i8, slot: *mut i32 }\n" ++
    "impl Drop for R:\n" ++
    "    fn drop(move self: Self):\n" ++
    "        unsafe:\n" ++
    "            *self.slot = *self.slot + self.id\n" ++
    "        free_mem(self.ptr)\n" ++
    "fn mk(id: i32, slot: *mut i32): R { id, ptr: alloc(16), slot }\n"

// A cell: name, generated source, expected final drop-sum printed by main,
// and whether the allocator must be clean (all cells, post-#691).
type Cell { name: str, source: str, expect_sum: i32, expect_clean: bool }

// `decls` holds the shape types and the `fn go(slot)` scenario; main just
// makes the slot, calls go, and prints the drop sum.
fn cell(name: str, decls: str, expect_sum: i32) -> Cell:
    let src = resource_prelude() ++ decls ++
        "fn main:\n" ++
        "    var drops: i32 = 0\n" ++
        "    let slot = &raw mut drops\n" ++
        "    go(slot)\n" ++
        "    print_i32(drops)\n"
    Cell { name: name, source: src, expect_sum: expect_sum, expect_clean: true }

// Shape wrappers: each returns (decls, make-expr(id), inner-access suffix).
// Scenario builders compose these; not every shape × scenario pair is
// meaningful — the matrix below curates the real cells.

fn shape_decls(shape: &str) -> str:
    if shape == "field":
        // Non-zero sibling: a blanked `r` must NOT make the whole S the reset
        // sentinel, or the whole-value guard masks a missing member guard (#697).
        return "type S { r: R, tag: i32 }\n"
    if shape == "boxfield":
        return "type SB { b: Box[R], tag: i32 }\n"
    if shape == "enum":
        return "enum E:\n    Carry(R)\n    Empty\n"
    ""

fn shape_ann(shape: &str) -> str:
    if shape == "option": return ": Option[R]"
    ""

fn shape_mk(shape: &str, id: &str) -> str:
    if shape == "bare": return "mk(" ++ id ++ ", slot)"
    if shape == "field": return "S { r: mk(" ++ id ++ ", slot), tag: 9 }"
    if shape == "boxfield": return "SB { b: Box.new(mk(" ++ id ++ ", slot)), tag: 9 }"
    if shape == "boxbare": return "Box.new(mk(" ++ id ++ ", slot))"
    if shape == "rcbare": return "Rc.new(mk(" ++ id ++ ", slot))"
    if shape == "tuple": return "(mk(" ++ id ++ ", slot), 7)"
    if shape == "option": return ".Some(mk(" ++ id ++ ", slot))"
    if shape == "enum": return "E.Carry(mk(" ++ id ++ ", slot))"
    "mk(" ++ id ++ ", slot)"

// The by-value type a consuming callee takes for each shape.
fn shape_ty(shape: &str) -> str:
    if shape == "field": return "S"
    if shape == "boxfield": return "SB"
    if shape == "boxbare": return "Box[R]"
    if shape == "rcbare": return "Rc[R]"
    if shape == "tuple": return "(R, i32)"
    if shape == "option": return "Option[R]"
    if shape == "enum": return "E"
    "R"

// ── Scenario builders ────────────────────────────────────────────────────

fn sc_scope_exit(shape: &str) -> str:
    shape_decls(shape) ++ "fn go(slot: *mut i32):\n    let a" ++ shape_ann(shape) ++ " = " ++ shape_mk(shape, "1") ++ "\n    let _keep = 0\n"

fn sc_branch(shape: &str, taken: bool) -> str:
    let flag = if taken: "true" else: "false"
    shape_decls(shape) ++
    "fn go(slot: *mut i32):\n" ++
    "    var flip = " ++ flag ++ "\n" ++
    "    if flip:\n" ++
    "        let a" ++ shape_ann(shape) ++ " = " ++ shape_mk(shape, "1") ++ "\n" ++
    "        let _k = 0\n"

fn sc_loop(shape: &str) -> str:
    shape_decls(shape) ++
    "fn go(slot: *mut i32):\n" ++
    "    for i in 0..3:\n" ++
    "        let a" ++ shape_ann(shape) ++ " = " ++ shape_mk(shape, "1") ++ "\n" ++
    "        let _k = 0\n"

fn sc_move_out(shape: &str) -> str:
    shape_decls(shape) ++
    "fn go(slot: *mut i32):\n" ++
    "    let a" ++ shape_ann(shape) ++ " = " ++ shape_mk(shape, "1") ++ "\n" ++
    "    let b = move a\n" ++
    "    let _k = 0\n"

fn sc_reassign(shape: &str) -> str:
    shape_decls(shape) ++
    "fn go(slot: *mut i32):\n" ++
    "    var a" ++ shape_ann(shape) ++ " = " ++ shape_mk(shape, "1") ++ "\n" ++
    "    a = " ++ shape_mk(shape, "2") ++ "\n" ++
    "    let _k = 0\n"

fn sc_move_then_reassign(shape: &str) -> str:
    shape_decls(shape) ++
    "fn go(slot: *mut i32):\n" ++
    "    var a" ++ shape_ann(shape) ++ " = " ++ shape_mk(shape, "1") ++ "\n" ++
    "    let b = move a\n" ++
    "    a = " ++ shape_mk(shape, "2") ++ "\n" ++
    "    let _k = 0\n"

// #691: an RHS call may consume and return the assignment target, so its
// reset must precede drop-before-overwrite. A direct self-move is a no-op.
fn sc_move_reassign_same_place(shape: &str) -> str:
    shape_decls(shape) ++
    "fn normalize(x: " ++ shape_ty(shape) ++ ") -> " ++ shape_ty(shape) ++ ":\n" ++
    "    var out = x\n" ++
    "    out\n" ++
    "fn go(slot: *mut i32):\n" ++
    "    var a" ++ shape_ann(shape) ++ " = " ++ shape_mk(shape, "1") ++ "\n" ++
    "    a = normalize(move a)\n" ++
    "    a = move a\n" ++
    "    for _i in 0..1:\n" ++
    "        a = normalize(move a)\n" ++
    "    let _k = 0\n"

fn sc_consume_call(shape: &str) -> str:
    shape_decls(shape) ++
    "fn eat(x: " ++ shape_ty(shape) ++ "):\n" ++
    "    let y = move x\n" ++
    "    let _k = 0\n" ++
    "fn go(slot: *mut i32):\n" ++
    "    let a" ++ shape_ann(shape) ++ " = " ++ shape_mk(shape, "1") ++ "\n" ++
    "    eat(move a)\n"

// #697 (t9 class): CONDITIONAL consume with a statement after the branch, so
// the paths merge and scope exit needs the guarded drop of a maybe-reset value.
// Without the trailing statement drops resolve per-path and the cell is vacuous.
fn sc_consume_cond(shape: &str, taken: bool) -> str:
    let flag = if taken: "true" else: "false"
    shape_decls(shape) ++
    "fn eat(x: " ++ shape_ty(shape) ++ "):\n" ++
    "    let y = move x\n" ++
    "    let _k = 0\n" ++
    "fn go(slot: *mut i32):\n" ++
    "    var a" ++ shape_ann(shape) ++ " = " ++ shape_mk(shape, "1") ++ "\n" ++
    "    var flip = " ++ flag ++ "\n" ++
    "    if flip:\n" ++
    "        eat(move a)\n" ++
    "    let _after = 0\n"

// #697 (t4/t5 class): a mut-receiver method moves a field out via a temp local
// (the only spelling today) and does not restore — the caller's scope-exit drop
// runs where the static moved-field exclusion cannot reach, so the runtime
// blank plus the member-level guard must make it exactly-once.
fn sc_field_take(shape: &str, restore: bool) -> str:
    let holder = shape_ty(shape)
    let member = if shape == "boxfield": "b" else: "r"
    let refill = if restore:
        "        self." ++ member ++ " = " ++ (if shape == "boxfield": "Box.new(mk(2, slot2))" else: "mk(2, slot2)") ++ "\n"
    else:
        ""
    shape_decls(shape) ++
    "fn eat(x: " ++ (if shape == "boxfield": "Box[R]" else: "R") ++ "):\n" ++
    "    let y = move x\n" ++
    "    let _k = 0\n" ++
    "extend " ++ holder ++ ":\n" ++
    "    mut fn feed(slot2: *mut i32):\n" ++
    "        var tmp = move self." ++ member ++ "\n" ++
    "        eat(move tmp)\n" ++
    refill ++
    "fn go(slot: *mut i32):\n" ++
    "    var h = " ++ shape_mk(shape, "1") ++ "\n" ++
    "    h.feed(slot)\n" ++
    "    let _after = h.tag\n"

// Finding 2 (rvalue-uniform `move`): moving into a callee whose param only
// reads (share-place). Exactly-once regardless of where the drop lands; the
// end-of-statement TIMING is pinned by the da_ fixture, not this count.
fn sc_move_into_borrow() -> str:
    "fn peek(x: R):\n" ++
    "    let _k = x.id\n" ++
    "fn go(slot: *mut i32):\n" ++
    "    var a = mk(1, slot)\n" ++
    "    peek(move a)\n" ++
    "    let _after = 0\n"

fn sc_early_return(shape: &str, early: bool) -> str:
    let flag = if early: "true" else: "false"
    shape_decls(shape) ++
    "fn go(slot: *mut i32):\n" ++
    "    let a" ++ shape_ann(shape) ++ " = " ++ shape_mk(shape, "1") ++ "\n" ++
    "    var e = " ++ flag ++ "\n" ++
    "    if e:\n" ++
    "        return\n" ++
    "    let _k = 0\n"

fn sc_discard(shape: &str) -> str:
    shape_decls(shape) ++ "fn go(slot: *mut i32):\n    let _" ++ shape_ann(shape) ++ " = " ++ shape_mk(shape, "1") ++ "\n"

fn sc_match_consume() -> str:
    shape_decls("enum") ++
    "fn go(slot: *mut i32):\n" ++
    "    let a = E.Carry(mk(1, slot))\n" ++
    "    let got = match a:\n" ++
    "        .Carry(r) => r.id\n" ++
    "        .Empty => 0\n" ++
    "    let _k = got\n"

fn sc_partial_move() -> str:
    // The callee must actually consume: a ()-body param infers no effects,
    // becomes share-place, and `take(s.r)` would borrow — testing no move.
    shape_decls("field") ++
    "fn take(r: R):\n" ++
    "    let sink = move r\n" ++
    "fn go(slot: *mut i32):\n" ++
    "    var s = " ++ shape_mk("field", "1") ++ "\n" ++
    "    var tmp = move s.r\n" ++
    "    take(move tmp)\n" ++
    "    let _k = s.tag\n"

// #706: a branch can remove a moved-field entry that predates its snapshot and
// add a different entry without changing the entry count. Length-only restore
// kept the replacement while truncating its path, causing an OOB read during
// the next field move. The early return keeps runtime drop state path-local.
fn sc_branch_move_state_identity() -> str:
    "type Pair { a: R, b: R }\n" ++
    "fn eat(x: R):\n" ++
    "    let y = move x\n" ++
    "fn go(slot: *mut i32):\n" ++
    "    var pair = Pair { a: mk(1, slot), b: mk(2, slot) }\n" ++
    "    var first = move pair.a\n" ++
    "    eat(move first)\n" ++
    "    var take_branch = true\n" ++
    "    if take_branch:\n" ++
    "        pair.a = mk(3, slot)\n" ++
    "        var second = move pair.b\n" ++
    "        eat(move second)\n" ++
    "        return\n" ++
    "    var fallback = move pair.b\n" ++
    "    eat(move fallback)\n"

fn sc_recv_mut() -> str:
    "extend R:\n    mut fn poke(): self.id = self.id + 0\n" ++
    "fn go(slot: *mut i32):\n" ++
    "    var a = mk(1, slot)\n" ++
    "    a.poke()\n" ++
    "    a.poke()\n"

fn sc_recv_move() -> str:
    "extend R:\n    move fn into_id() -> i32: self.id\n" ++
    "fn go(slot: *mut i32):\n" ++
    "    let a = mk(1, slot)\n" ++
    "    let _got = a.into_id()\n"

fn sc_recv_replace() -> str:
    "extend R:\n    mut fn renew(slot2: *mut i32): self = mk(2, slot2)\n" ++
    "fn go(slot: *mut i32):\n" ++
    "    var a = mk(1, slot)\n" ++
    "    a.renew(slot)\n"

// #1486 (§12.4): a non-escaping closure captures a non-Copy local by place
// and assigns it. The old value drops at the ORIGINAL place (id 1), the new
// one at scope exit (id 2) — exactly once each, through the capture pointer.
// The audit was blind to closures before this cell: the drop of the old
// value freed the closure's pointer slot instead of what it points at.
fn sc_closure_assign(shape: &str) -> str:
    shape_decls(shape) ++
    "fn run_unit(f: fn() -> Unit): f()\n" ++
    "fn go(slot: *mut i32):\n" ++
    "    var a" ++ shape_ann(shape) ++ " = " ++ shape_mk(shape, "1") ++ "\n" ++
    // `.Some(...)` inside a closure loses its captures (#1570): spell `Some`.
    "    run_unit(() => a = " ++ shape_mk(shape, "2").replace(".Some(", "Some(") ++ ")\n" ++
    "    let _k = 0\n"

// The same assignment made twice by one non-escaping closure: 1 + 2 + 3.
// The next id is read from the by-place capture itself (a Copy counter
// capture is a snapshot today, #1486's open i32 question).
fn sc_closure_assign_twice() -> str:
    "fn run_twice(f: fn() -> Unit):\n    f()\n    f()\n" ++
    "fn go(slot: *mut i32):\n" ++
    "    var a = mk(1, slot)\n" ++
    "    run_twice(() => a = mk(a.id + 1, slot))\n" ++
    "    let _k = 0\n"

// #1481 (§12.4): a let-bound closure captures by place too — the spec's
// `let f = || xs.push(1); f()` — so an assignment through it drops the old
// value at the original place (1) and the new one at scope exit (2).
fn sc_closure_let_bound_assign() -> str:
    "fn go(slot: *mut i32):\n" ++
    "    var a = mk(1, slot)\n" ++
    "    let f = () => a = mk(2, slot)\n" ++
    "    f()\n" ++
    "    let _k = 0\n"

// #1481: a closure whose body returns its capture consumes the place when
// called — the value moves out once (dropped as `b`), the blanked place
// frees nothing at scope exit. let-bound and direct-argument forms.
fn sc_closure_consume(direct: bool) -> str:
    "fn run_r(f: fn() -> R) -> R: f()\n" ++
    "fn go(slot: *mut i32):\n" ++
    "    let a = mk(1, slot)\n" ++
    (if direct: "    let b = run_r(() => a)\n" else: "    let f: fn() -> R = () => a\n    let b = f()\n") ++
    "    let _k = 0\n"

fn sc_vec_elem() -> str:
    "fn go(slot: *mut i32):\n" ++
    "    var v: Vec[R] = Vec.new()\n" ++
    "    v.push(mk(1, slot))\n" ++
    "    v.push(mk(2, slot))\n" ++
    "    let _k = 0\n"

// #1390: an f-string hole observes its value. An owned temporary there — the
// R a call builds, the str a call returns — has only its statement to drop
// it: exactly once, never leaked (the allocator verdict), never freed while
// the hole still reads it.
fn sc_fstring_hole(form: &str) -> str:
    let hole = if form == "field": "{mk(1, slot).id}" else if form == "method": "{mk(1, slot).label()}" else if form == "concat": "{mk(1, slot).label() ++ \"!\"}" else if form == "slice": "{mk(1, slot).label().slice(0, 1)}" else: "{mk(1, slot).label().slice(0, 1):>6}"
    "extend R:\n    fn label() -> str: f\"r{self.id}\"\n" ++
    "fn go(slot: *mut i32):\n" ++
    "    let text = f\"<" ++ hole ++ ">\"\n" ++
    "    let _n = text.len()\n"

// #1392: the built-in display of an enum or struct formats each part into a
// str of its own and joins them. Every part and every intermediate join is
// freed exactly once; a str payload is copied first, so the value keeps its
// own. (R itself has no display — its fields are raw pointers — so these
// cells format values beside it; the allocator verdict is the check.)
fn sc_display(form: &str) -> str:
    let value = if form == "enum": "Tag.Named(r.id, \"n\" ++ \"m\")" else if form == "nested": "Some(Tag.Named(r.id, \"n\" ++ \"m\"))" else: "Row { n: r.id, s: \"a\" ++ \"b\" }"
    "enum Tag:\n    Named(i32, str)\n    Bare\n" ++
    "type Row { n: i32, s: str }\n" ++
    "fn go(slot: *mut i32):\n" ++
    "    let r = mk(1, slot)\n" ++
    "    let v = " ++ value ++ "\n" ++
    "    let text = f\"{v:?}\"\n" ++
    "    let _n = text.len()\n"

// #1403 (§13.5/§13.6): a comprehension clause's refutable pattern skips the
// elements it does not match. Over consuming iteration a skipped element is
// the clause's to drop (exactly once, at the skip); a bound one moves into
// the result. Over a view, nothing moves. Every R (1 + 2 + 4) drops once.
fn sc_comprehension_skip(form: &str) -> str:
    var fill = "    var v: Vec[(i32, R)] = Vec.new()\n    v.push((0, mk(1, slot)))\n    v.push((1, mk(2, slot)))\n    v.push((0, mk(4, slot)))\n"
    var comp = "[r for (0, r) in v.into_iter()]"
    if form == "option":
        fill = "    var v: Vec[Option[R]] = Vec.new()\n    v.push(Some(mk(1, slot)))\n    v.push(None)\n    v.push(Some(mk(2, slot)))\n    v.push(Some(mk(4, slot)))\n"
        comp = "[r for Some(r) in v.into_iter()]"
    else if form == "view":
        comp = "[r.id for (0, r) in v]"
    "fn go(slot: *mut i32):\n" ++ fill ++
    "    let kept = " ++ comp ++ "\n" ++
    "    let _n = kept.len()\n"

// #1408/#1409 (§3.8 join rule 3): a join of field places is a view — no arm
// moves its field, and the owner drops the R once at its own scope exit.
// `form`: an if, a match, a block-tail arm, through a read `fn` receiver.
fn sc_field_join_view(form: &str) -> str:
    let join = if form == "match": "match c:\n            true => h.r\n            false => h.r" else if form == "block": "if c: { let _n = 0\n        h.r } else: h.r" else: "if c: h.r else: h.r"
    if form == "recv":
        return "type HR { r: R }\n" ++
            "extend HR:\n    fn look(c: bool) -> i32:\n        let x = if c: self.r else: self.r\n        x.id\n" ++
            "fn go(slot: *mut i32):\n" ++
            "    let h = HR { r: mk(1, slot) }\n" ++
            "    let _k = h.look(true) + h.look(false)\n"
    "type HR { r: R }\n" ++
    "fn go(slot: *mut i32):\n" ++
    "    let h = HR { r: mk(1, slot) }\n" ++
    "    for i in 0..2:\n" ++
    "        let c = i == 0\n" ++
    "        let x = " ++ join ++ "\n" ++
    "        let _k = x.id + h.r.id\n"

// #1464 (§14.4, §14.7): a task handle in a local owns the result buffer its
// `.await` frees, and the awaited R drops once. An unannotated async fn's
// call was typed as the awaited T, so the handle sat in an R-typed local
// (the base run of the inferred cell dies with no output).
fn sc_async_await(annotated: bool) -> str:
    let ret = if annotated: " -> R" else: ""
    "async fn make(slot: *mut i32)" ++ ret ++ ": mk(1, slot)\n" ++
    "fn go(slot: *mut i32):\n" ++
    "    let t = make(slot)\n" ++
    "    let r = t.await\n" ++
    "    let _k = r.id\n"

// #1412 (§13.4): a generator yields an R built with statement temporaries
// (an f-string part beside it); each yielded R drops once in the consumer,
// the temporaries once on the suspending path, and a `let` moved into the
// yield is not dropped again from the saved state (a named str that stays
// in the state is #1548, not this cell). `stop` breaks after the
// first element: the abandoned generator state drops nothing twice.
fn sc_generator_yield(stop: bool) -> str:
    let body = if stop: "        let _k = r.id\n        break\n" else: "        let _k = r.id\n"
    "gen fn each(slot: *mut i32) -> R:\n" ++
    "    var i = 1\n" ++
    "    while i < 3:\n" ++
    "        let r = mk(i, slot)\n" ++
    "        let _n = f\"t{i}\".len()\n" ++
    "        yield r\n" ++
    "        i += 1\n" ++
    "fn go(slot: *mut i32):\n" ++
    "    for r in each(slot):\n" ++ body

// #1365 (§9.7, §2.4): `let PAT = subject else: <diverge>` consumes its
// subject on both paths. The failing path drops the whole subject — whichever
// variant it holds — exactly once before it diverges; the matching path moves
// the bound part into the binding and `..` drops the rest. The matching value
// carries id 1 (plus id 4 in the struct's unbound field), the failing one id 2.
fn le_ty(shape: &str) -> str:
    if shape == "result": return "Result[R, R]"
    if shape == "option": return "Option[R]"
    if shape == "enum": return "E2"
    if shape == "nested": return "Option[E2]"
    "Result[P, R]"

fn le_hit(shape: &str) -> str:
    if shape == "result": return "Ok(mk(1, slot))"
    if shape == "option": return "Some(mk(1, slot))"
    if shape == "enum": return "E2.A(mk(1, slot))"
    if shape == "nested": return "Some(E2.A(mk(1, slot)))"
    "Ok(P { a: mk(1, slot), b: mk(4, slot) })"

fn le_miss(shape: &str) -> str:
    if shape == "option": return "None"
    if shape == "enum": return "E2.B(mk(2, slot))"
    if shape == "nested": return "Some(E2.B(mk(2, slot)))"
    "Err(mk(2, slot))"

fn le_pat(shape: &str) -> str:
    if shape == "result": return "Ok(v)"
    if shape == "option": return "Some(v)"
    if shape == "enum": return ".A(v)"
    if shape == "nested": return "Some(.A(v))"
    "Ok(P { a: v, .. })"

// `exit` is return | break | continue; `local` binds the subject to a named
// local first, otherwise the subject is the call's temporary.
fn sc_let_else(shape: &str, hit: bool, exit: &str, local: bool) -> str:
    let flag = if hit: "true" else: "false"
    let ind = if exit == "return": "    " else: "        "
    let subject = if local: "s" else: "make_subject(" ++ flag ++ ", slot)"
    let bind = if local: ind ++ "let s = make_subject(" ++ flag ++ ", slot)\n" else: ""
    let stmt = ind ++ "let " ++ le_pat(shape) ++ " = " ++ subject ++ " else: " ++ exit ++ "\n" ++ ind ++ "let _k = v.id\n"
    let body = (if exit == "return": "" else: "    for _i in 0..1:\n") ++ bind ++ stmt
    "type P { a: R, b: R }\n" ++
    "enum E2:\n    A(R)\n    B(R)\n" ++
    "fn make_subject(k: bool, slot: *mut i32) -> " ++ le_ty(shape) ++ ":\n" ++
    "    if k: " ++ le_hit(shape) ++ " else: " ++ le_miss(shape) ++ "\n" ++
    "fn go(slot: *mut i32):\n" ++ body

// #1383: the else branch consumes an outer value, then diverges. The value
// moves on that path only: the matching path still owns it whole (its drop
// adds 8), the failing path hands it to `eat` (which drops it) after the
// subject (2) drops. A blank leaking onto the matching path shows as a lost
// 8 and a leaked block. `form`: inline `else: return eat(..)`, a block else,
// or a vacated field (`move h.r`).
fn sc_let_else_consume(form: &str, hit: bool) -> str:
    let flag = if hit: "true" else: "false"
    let owner = if form == "field": "    var h = H { r: mk(8, slot) }\n" else: "    let keep = mk(8, slot)\n"
    let taken = if form == "field": "move h.r" else: "keep"
    let read = if form == "field": "h.r.id" else: "keep.id"
    let els = if form == "block": "else:\n        eat(" ++ taken ++ ")\n        return\n" else: "else: return eat(" ++ taken ++ ")\n"
    "type H { r: R }\n" ++
    "fn eat(x: R): ()\n" ++
    "fn make_subject(k: bool, slot: *mut i32) -> Result[R, R]:\n" ++
    "    if k: Ok(mk(1, slot)) else: Err(mk(2, slot))\n" ++
    "fn go(slot: *mut i32):\n" ++ owner ++
    "    let Ok(v) = make_subject(" ++ flag ++ ", slot) " ++ els ++
    "    let _k = v.id + " ++ read ++ "\n"

fn le_sum(shape: &str, hit: bool) -> i32:
    if not hit: return if shape == "option": 0 else: 2
    if shape == "struct": 5 else: 1

// POD-container cells: #691/D18 — every Vec frees its buffer at scope exit
// and on reassignment, so the allocator verdict must be CLEAN.
fn pod_cell(name: str, body: str) -> Cell:
    let src = "use std.builtins.print_i32\n" ++ "fn main:\n" ++ body ++ "    print_i32(0)\n"
    Cell { name: name, source: src, expect_sum: 0, expect_clean: true }

fn sc_slotmap(kind: &str):
    var source = "use std.collections\nfn go(slot: *mut i32):\n    var map = SlotMap[R].new()\n"
    if kind == "empty": return source
    source = source ++ "    let handles: Vec[Handle[R]] = Vec.new()\n" ++
        "    for i in 1..129: handles.push(map.insert(mk(i, slot)))\n"
    if kind == "partial" or kind == "refill":
        source = source ++ "    for i in 0..128:\n" ++
            "        if i % 2 == 0:\n" ++
            "            let removed = map.remove(handles[i]).unwrap()\n" ++
            "            assert(removed.id == i + 1)\n" ++
            "            assert(not map.contains(handles[i]))\n"
    if kind == "refill":
        source = source ++ "    for i in 0..64: map.insert(mk(1, slot))\n" ++
            "    assert(map.len() == 128)\n"
    source

// Phase 1 facade cells (docs/stdlib_sourcing_plan.md "Facade rules"): every
// value a c-algorithms-backed facade holds drops exactly once — empty,
// full, after partial transfers, and after a cursor abandoned midway.
// R orders by id through Ord.cmp, which backs the facades' `<` / `>` (§11.7).
fn sc_facade_prelude(facade: &str):
    "use std.collections." ++ facade ++ "\n" ++
    "impl Ord for R:\n" ++
    "    fn cmp(other: &R) -> i32: if self.id < other.id: -1 else if self.id > other.id: 1 else: 0\n"

fn sc_sorted_vec(kind: &str):
    var source = sc_facade_prelude("sorted_vec.SortedVec") ++ "fn go(slot: *mut i32):\n    var sorted = SortedVec[R].new()\n"
    if kind == "empty": return source
    source = source ++ "    for i in 1..9: sorted.insert(mk(9 - i, slot))\n" ++
        "    assert(sorted.get(0).id == 1 and sorted.get(7).id == 8)\n"
    if kind == "partial":
        source = source ++ "    for i in 0..4:\n        let removed = sorted.remove(0)\n        assert(removed.id == i + 1)\n" ++
            "    assert(sorted.len() == 4)\n"
    if kind == "cursor":
        source = source ++ "    var cursor = sorted.iter()\n    assert(cursor.next().unwrap().id == 1)\n    assert(cursor.next().unwrap().id == 2)\n"
    source

fn sc_binary_heap(kind: &str):
    var source = sc_facade_prelude("binary_heap.BinaryHeap") ++ "fn go(slot: *mut i32):\n    var heap = BinaryHeap[R].new()\n"
    if kind == "empty": return source
    source = source ++ "    for i in 1..9: heap.push(mk(i, slot))\n    assert(heap.peek().unwrap().id == 8)\n"
    if kind == "partial":
        source = source ++ "    for i in 0..4:\n        let top = heap.pop().unwrap()\n        assert(top.id == 8 - i)\n    assert(heap.len() == 4)\n"
    source

fn sc_trie(kind: &str):
    var source = sc_facade_prelude("trie.Trie") ++ "fn go(slot: *mut i32):\n    var trie = Trie[R].new()\n"
    if kind == "empty": return source
    source = source ++ "    for i in 1..9: assert(trie.insert(f\"k{i}\", mk(i, slot)).is_none())\n    assert(trie.len() == 8)\n"
    if kind == "partial":
        source = source ++ "    for i in 1..5:\n        let removed = trie.remove(f\"k{i}\").unwrap()\n        assert(removed.id == i)\n    assert(trie.len() == 4)\n"
    if kind == "replace":
        source = source ++ "    let old = trie.insert(\"k3\", mk(3, slot)).unwrap()\n    assert(old.id == 3)\n"
    if kind == "cursor":
        source = source ++ "    var cursor = trie.iter_prefix(\"k\")\n    assert(cursor.next().unwrap().id == 1)\n"
    source

// HashIndex[i32, R] over the TommyDS hashdyn engine (Phase 2): the facade
// owns every node; a replaced value transfers out, removals transfer, the
// index drops the rest exactly once.
fn sc_hash_index(kind: &str):
    var source = "use std.collections.hash_index.HashIndex\nfn go(slot: *mut i32):\n    var index = HashIndex[i32, R].new()\n"
    if kind == "empty": return source
    source = source ++ "    for i in 1..9: assert(index.insert(i, mk(i, slot)).is_none())\n    assert(index.len() == 8 and index.get(&3).unwrap().id == 3)\n"
    if kind == "partial":
        source = source ++ "    for i in 1..5:\n        let removed = index.remove(&i).unwrap()\n        assert(removed.id == i)\n    assert(index.len() == 4)\n"
    if kind == "replace":
        source = source ++ "    let old = index.insert(3, mk(3, slot)).unwrap()\n    assert(old.id == 3)\n"
    if kind == "cursor":
        source = source ++ "    var cursor = index.iter()\n    var seen = 0\n    while let Some(entry) = cursor.next():\n        assert(entry.value().id == *entry.key())\n        seen = seen + 1\n    assert(seen == 8)\n"
    source

fn build_cells():
    var cells: Vec[Cell] = Vec.new()
    cells.push(cell("hash_index_empty/facade", sc_hash_index("empty"), 0))
    cells.push(cell("hash_index_full/facade", sc_hash_index("full"), 36))
    cells.push(cell("hash_index_partial/facade", sc_hash_index("partial"), 36))
    cells.push(cell("hash_index_replace/facade", sc_hash_index("replace"), 39))
    cells.push(cell("hash_index_cursor/facade", sc_hash_index("cursor"), 36))
    cells.push(cell("sorted_vec_empty/facade", sc_sorted_vec("empty"), 0))
    cells.push(cell("sorted_vec_full/facade", sc_sorted_vec("full"), 36))
    cells.push(cell("sorted_vec_partial/facade", sc_sorted_vec("partial"), 36))
    cells.push(cell("sorted_vec_cursor/facade", sc_sorted_vec("cursor"), 36))
    cells.push(cell("binary_heap_empty/facade", sc_binary_heap("empty"), 0))
    cells.push(cell("binary_heap_full/facade", sc_binary_heap("full"), 36))
    cells.push(cell("binary_heap_partial/facade", sc_binary_heap("partial"), 36))
    cells.push(cell("trie_empty/facade", sc_trie("empty"), 0))
    cells.push(cell("trie_full/facade", sc_trie("full"), 36))
    cells.push(cell("trie_partial/facade", sc_trie("partial"), 36))
    cells.push(cell("trie_replace/facade", sc_trie("replace"), 39))
    cells.push(cell("trie_cursor/facade", sc_trie("cursor"), 36))
    cells.push(cell("slotmap_empty/slotmap", sc_slotmap("empty"), 0))
    cells.push(cell("slotmap_full/slotmap", sc_slotmap("full"), 8256))
    cells.push(cell("slotmap_partial/slotmap", sc_slotmap("partial"), 8256))
    cells.push(cell("slotmap_refill/slotmap", sc_slotmap("refill"), 8320))
    for sh in ["bare", "field", "tuple", "option", "enum", "boxbare", "rcbare", "boxfield"]:
        cells.push(cell("scope_exit/" ++ sh, sc_scope_exit(sh), 1))
        cells.push(cell("branch_taken/" ++ sh, sc_branch(sh, true), 1))
        cells.push(cell("branch_untaken/" ++ sh, sc_branch(sh, false), 0))
        cells.push(cell("loop3/" ++ sh, sc_loop(sh), 3))
        cells.push(cell("move_out/" ++ sh, sc_move_out(sh), 1))
        cells.push(cell("reassign_over/" ++ sh, sc_reassign(sh), 3))
        cells.push(cell("move_then_reassign/" ++ sh, sc_move_then_reassign(sh), 3))
        cells.push(cell("early_return/" ++ sh, sc_early_return(sh, true), 1))
        cells.push(cell("normal_return/" ++ sh, sc_early_return(sh, false), 1))
        cells.push(cell("discard/" ++ sh, sc_discard(sh), 1))
        // #697: conditional consume with a post-branch statement (merged drop).
        cells.push(cell("consume_cond_taken/" ++ sh, sc_consume_cond(sh, true), 1))
        cells.push(cell("consume_cond_untaken/" ++ sh, sc_consume_cond(sh, false), 1))
    cells.push(cell("consume_call/bare", sc_consume_call("bare"), 1))
    cells.push(cell("consume_call/field", sc_consume_call("field"), 1))
    cells.push(cell("consume_call/boxbare", sc_consume_call("boxbare"), 1))
    cells.push(cell("consume_call/rcbare", sc_consume_call("rcbare"), 1))
    cells.push(cell("match_consume/enum", sc_match_consume(), 1))
    cells.push(cell("partial_move/field", sc_partial_move(), 1))
    cells.push(cell("branch_move_state_identity/field", sc_branch_move_state_identity(), 6))
    cells.push(cell("move_reassign_same_place/bare", sc_move_reassign_same_place("bare"), 1))
    // #697: share-place receiver field take (caller-side drop of the holder).
    cells.push(cell("field_take/field", sc_field_take("field", false), 1))
    cells.push(cell("field_take/boxfield", sc_field_take("boxfield", false), 1))
    cells.push(cell("field_take_restore/field", sc_field_take("field", true), 3))
    cells.push(cell("field_take_restore/boxfield", sc_field_take("boxfield", true), 3))
    // Finding 2: move into a borrowing (share-place) callee — exactly-once.
    cells.push(cell("move_into_borrow/bare", sc_move_into_borrow(), 1))
    cells.push(cell("recv_mut_borrow/bare", sc_recv_mut(), 1))
    cells.push(cell("recv_move_consume/bare", sc_recv_move(), 1))
    cells.push(cell("recv_bare_self_replace/bare", sc_recv_replace(), 3))
    cells.push(cell("vec_elem_drop/vec", sc_vec_elem(), 3))
    for form in ["field", "method", "concat", "slice", "spec"]:
        cells.push(cell("fstring_hole_temp_" ++ form ++ "/bare", sc_fstring_hole(form), 1))
    for form in ["enum", "nested", "struct"]:
        cells.push(cell("display_parts_" ++ form ++ "/" ++ form, sc_display(form), 1))
    for sh in ["bare", "field", "tuple", "option", "enum", "boxbare", "rcbare", "boxfield"]:
        cells.push(cell("closure_assign/" ++ sh, sc_closure_assign(sh), 3))
    cells.push(cell("closure_assign_twice/bare", sc_closure_assign_twice(), 6))
    cells.push(cell("closure_let_bound_assign/bare", sc_closure_let_bound_assign(), 3))
    cells.push(cell("closure_consume_direct/bare", sc_closure_consume(true), 1))
    cells.push(cell("closure_consume_let_bound/bare", sc_closure_consume(false), 1))
    for sh in ["result", "option", "enum", "nested", "struct"]:
        for subj in ["temp", "local"]:
            let local = subj == "local"
            cells.push(cell("let_else_hit_" ++ subj ++ "/" ++ sh, sc_let_else(sh, true, "return", local), le_sum(sh, true)))
            for exit in ["return", "break", "continue"]:
                cells.push(cell("let_else_miss_" ++ exit ++ "_" ++ subj ++ "/" ++ sh, sc_let_else(sh, false, exit, local), le_sum(sh, false)))
    for form in ["tuple", "option", "view"]:
        cells.push(cell("comprehension_skip_" ++ form ++ "/bare", sc_comprehension_skip(form), 7))
    for form in ["if", "match", "block", "recv"]:
        cells.push(cell("field_join_view_" ++ form ++ "/field", sc_field_join_view(form), 1))
    cells.push(cell("async_await_inferred/bare", sc_async_await(false), 1))
    cells.push(cell("async_await_annotated/bare", sc_async_await(true), 1))
    cells.push(cell("generator_yield_full/bare", sc_generator_yield(false), 3))
    cells.push(cell("generator_yield_stop/bare", sc_generator_yield(true), 1))
    for form in ["inline", "block", "field"]:
        cells.push(cell("let_else_consume_hit_" ++ form ++ "/bare", sc_let_else_consume(form, true), 9))
        cells.push(cell("let_else_consume_miss_" ++ form ++ "/bare", sc_let_else_consume(form, false), 10))
    cells.push(pod_cell("pod_vec_scope_exit/EXPECT-CLEAN", "    var v: Vec[i32] = Vec.new()\n    v.push(1)\n"))
    cells.push(pod_cell("pod_vec_reassign/EXPECT-CLEAN", "    var v: Vec[i32] = Vec.new()\n    v.push(1)\n    var w: Vec[i32] = Vec.new()\n    w.push(2)\n    v = w\n"))
    cells

// ── Runner ───────────────────────────────────────────────────────────────

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

fn last_int_line(s: str) -> str:
    // Last non-empty stdout line = the printed drop sum.
    let lines = s.split("\n")
    var i = lines.len() as i32 - 1
    while i >= 0:
        let l = lines[i]
        if l.len() > 0:
            return l ++ ""
        i = i - 1
    ""

fn run_cell(with_bin: &str, dir: &str, idx: i32, source: &str, expect_sum: i32, expect_clean: bool) -> str:
    let path = dir ++ f"/cell_{idx}.w"
    let _ = write_file(path, source)
    let outp = dir ++ f"/cell_{idx}.out"
    let errp = dir ++ f"/cell_{idx}.err"
    let rc = exec_capture(argv4(with_bin, "run", "--debug-alloc", path), outp, errp, 60000)
    let err = read_file(errp)
    let out = read_file(outp)
    if find_sub(err, "error:") >= 0:
        return "COMPILE-FAIL"
    if find_sub(err, "DOUBLE FREE") >= 0 or find_sub(err, "double free") >= 0:
        return "DOUBLE-FREE"
    let leaked = find_sub(err, "LEAK") >= 0
    if expect_clean and leaked:
        return "LEAK"
    if not expect_clean and not leaked:
        return "UNEXPECTED-CLEAN"
    if rc != 0 and find_sub(err, "leak count") < 0:
        return "RUN-FAIL"
    let got = last_int_line(out)
    let want = f"{expect_sum}"
    if got != want:
        return "VALUE-FAIL(got=" ++ got ++ " want=" ++ want ++ ")"
    "PASS"

fn main:
    let argv = args()
    if argv.len() < 2:
        eprint("usage: with run tools/drop_audit.w <candidate-with> [baseline-with]")
        exit_code(2)
    let candidate = argv.get(1)
    let baseline = if argv.len() >= 3: argv.get(2) ++ "" else: ""
    // Keep both sides' diagnostics; the baseline must not overwrite the
    // failing candidate's stderr. A separate directory per run also keeps
    // concurrent invocations from replacing one another's probes.
    let dir = f"out/drop-audit/cells-{pid()}"
    let candidate_dir = dir ++ "/candidate"
    let baseline_dir = dir ++ "/baseline"
    if mkdirs(candidate_dir) != 0 or mkdirs(baseline_dir) != 0:
        eprint("drop-audit: could not create probe directories: " ++ dir)
        exit_code(1)
    let cells = build_cells()
    var failures = 0
    var regressions = 0
    print("cell\tcandidate" ++ (if baseline.len() > 0: "\tbaseline\tclass" else: ""))
    for i in 0..cells.len():
        let c = cells[i]
        let cv = run_cell(candidate, candidate_dir, i, c.source, c.expect_sum, c.expect_clean)
        var row = c.name ++ "\t" ++ cv
        if baseline.len() > 0:
            let bv = run_cell(baseline, baseline_dir, i, c.source, c.expect_sum, c.expect_clean)
            let klass = if cv == bv: "same" else if cv == "PASS": "FIXED" else: "REGRESSION"
            if klass == "REGRESSION":
                regressions = regressions + 1
            row = row ++ "\t" ++ bv ++ "\t" ++ klass
        if cv != "PASS":
            failures = failures + 1
        print(row)
    if baseline.len() > 0:
        print(f"drop-audit: {cells.len()} cells, {failures} non-PASS, {regressions} regressions vs baseline")
        if regressions > 0:
            eprint("drop-audit: probes and diagnostics retained: " ++ dir)
            exit_code(1)
    else:
        print(f"drop-audit: {cells.len()} cells, {failures} non-PASS")
        if failures > 0:
            eprint("drop-audit: probes and diagnostics retained: " ++ dir)
            exit_code(1)
    exit_code(0)
