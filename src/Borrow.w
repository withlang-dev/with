// Borrow — Borrow checker operating on MIR CFG.
//
// Enforces the aliasing rule (spec §3.2):
//   For any value, at any point:
//     - Any number of &T (shared borrows), OR
//     - Exactly one &mut T (exclusive borrow)
//     - Never both.
//
// Uses NLL (Non-Lexical Lifetimes) regions computed by
// walking the CFG backwards from last use.
//
// Ref: .reference/rust/compiler/rustc_borrowck/
// Ref: bootstrap/Sema.zig (NLL section)

use Type
use Mir

// ── Borrow info ──────────────────────────────────────────────────────

type BorrowInfo = {
    kind: i32,          // BK_SHARED or BK_MUTABLE
    local: i32,         // what is borrowed (local id)
    field: i32,         // field index if field borrow, -1 otherwise
    created_bb: i32,    // basic block where borrow was created
    created_stmt: i32,  // statement index where borrow was created
    ref_local: i32,     // local holding the reference
    span_start: i32,
    span_end: i32,
}

fn BorrowInfo.new(kind: i32, local: i32, ref_local: i32, bb: i32, stmt: i32) -> BorrowInfo:
    BorrowInfo {
        kind: kind,
        local: local,
        field: -1,
        created_bb: bb,
        created_stmt: stmt,
        ref_local: ref_local,
        span_start: 0,
        span_end: 0,
    }

// ── NLL Region ───────────────────────────────────────────────────────
// A region is the set of basic blocks where a borrow is live.

type NllRegion = {
    blocks: Vec[i32],
}

fn NllRegion.new() -> NllRegion:
    NllRegion {
        blocks: Vec.new(),
    }

fn NllRegion.add(self: NllRegion, bb: i32) -> void:
    // Check if already present
    let count = self.blocks.len() as i32
    var i = 0
    while i < count:
        if self.blocks.get(i as i64) == bb:
            return
        i = i + 1
    self.blocks.push(bb)

fn NllRegion.contains(self: NllRegion, bb: i32) -> bool:
    let count = self.blocks.len() as i32
    var i = 0
    while i < count:
        if self.blocks.get(i as i64) == bb:
            return true
        i = i + 1
    false

// ── Borrow checker state ─────────────────────────────────────────────

type BorrowChecker = {
    body: MirBody,
    types: TypeTable,
    borrows: Vec[BorrowInfo],
    regions: Vec[NllRegion],
    errors: Vec[str],
    error_starts: Vec[i32],
    error_ends: Vec[i32],
}

fn BorrowChecker.new(body: MirBody, types: TypeTable) -> BorrowChecker:
    BorrowChecker {
        body: body,
        types: types,
        borrows: Vec.new(),
        regions: Vec.new(),
        errors: Vec.new(),
        error_starts: Vec.new(),
        error_ends: Vec.new(),
    }

fn BorrowChecker.error_count(self: BorrowChecker) -> i32:
    self.errors.len() as i32

fn BorrowChecker.get_error(self: BorrowChecker, idx: i32) -> str:
    self.errors.get(idx as i64)

fn BorrowChecker.emit_error(self: BorrowChecker, msg: str, start: i32, end: i32) -> void:
    self.errors.push(msg)
    self.error_starts.push(start)
    self.error_ends.push(end)

// ── Main checking entry point ────────────────────────────────────────

fn BorrowChecker.check(self: BorrowChecker) -> void:
    // Phase 1: Collect all borrows from MIR statements
    BorrowChecker.collect_borrows(self)
    // Phase 2: Compute NLL regions for each borrow
    BorrowChecker.compute_regions(self)
    // Phase 3: Check for conflicts at each statement
    BorrowChecker.check_conflicts(self)

// ── Phase 1: Collect borrows ─────────────────────────────────────────

fn BorrowChecker.collect_borrows(self: BorrowChecker) -> void:
    let stmt_count = MirBody.stmt_count(self.body)
    var i = 0
    while i < stmt_count:
        let kind = MirBody.stmt_kind(self.body, i)
        if kind == SK_ASSIGN():
            let dest = MirBody.stmt_d0(self.body, i)
            let rv_kind = MirBody.stmt_d1(self.body, i)
            let rv_d0 = MirBody.stmt_d2(self.body, i)
            if rv_kind == RV_REF():
                // This is a borrow: dest = &local or dest = &mut local
                // Determine borrow kind from the local's mutability or context
                let borrow = BorrowInfo.new(BK_SHARED(), rv_d0, dest, 0, i)
                self.borrows.push(borrow)
                self.regions.push(NllRegion.new())
        i = i + 1

// ── Phase 2: Compute NLL regions ─────────────────────────────────────

fn BorrowChecker.compute_regions(self: BorrowChecker) -> void:
    let borrow_count = self.borrows.len() as i32
    var bi = 0
    while bi < borrow_count:
        let borrow = self.borrows.get(bi as i64)
        let region = self.regions.get(bi as i64)
        // For each borrow, add the creation block
        NllRegion.add(region, borrow.created_bb)
        // Walk forward from creation to find last use of ref_local
        // (simplified: add all reachable blocks from creation)
        let bb_count = MirBody.block_count(self.body)
        var bb = borrow.created_bb
        while bb < bb_count:
            // Check if ref_local is used in this block
            if BorrowChecker.block_uses_local(self, bb, borrow.ref_local):
                NllRegion.add(region, bb)
            bb = bb + 1
        bi = bi + 1

fn BorrowChecker.block_uses_local(self: BorrowChecker, bb: i32, local: i32) -> bool:
    // Check if any statement in bb reads from local
    let stmt_count = MirBody.stmt_count(self.body)
    var i = 0
    while i < stmt_count:
        let kind = MirBody.stmt_kind(self.body, i)
        if kind == SK_ASSIGN():
            let src = MirBody.stmt_d2(self.body, i)
            if src == local:
                return true
        i = i + 1
    false

// ── Phase 3: Check for conflicts ─────────────────────────────────────

fn BorrowChecker.check_conflicts(self: BorrowChecker) -> void:
    let borrow_count = self.borrows.len() as i32
    // Check pairwise conflicts
    var i = 0
    while i < borrow_count:
        let bi = self.borrows.get(i as i64)
        let ri = self.regions.get(i as i64)
        var j = i + 1
        while j < borrow_count:
            let bj = self.borrows.get(j as i64)
            let rj = self.regions.get(j as i64)
            // Same local being borrowed?
            if bi.local == bj.local:
                // Check if regions overlap
                if BorrowChecker.regions_overlap(self, ri, rj):
                    // Check conflict: mut+mut, mut+shared, shared+mut
                    if bi.kind == BK_MUTABLE():
                        BorrowChecker.emit_error(self, "cannot borrow as mutable more than once", bi.span_start, bi.span_end)
                    if bj.kind == BK_MUTABLE():
                        if bi.kind == BK_SHARED():
                            BorrowChecker.emit_error(self, "cannot borrow as mutable while shared borrow exists", bj.span_start, bj.span_end)
            j = j + 1
        i = i + 1
    // Check writes to borrowed locals
    BorrowChecker.check_writes_to_borrowed(self)

fn BorrowChecker.regions_overlap(self: BorrowChecker, a: NllRegion, b: NllRegion) -> bool:
    let ac = a.blocks.len() as i32
    var i = 0
    while i < ac:
        let bb = a.blocks.get(i as i64)
        if NllRegion.contains(b, bb):
            return true
        i = i + 1
    false

fn BorrowChecker.check_writes_to_borrowed(self: BorrowChecker) -> void:
    let stmt_count = MirBody.stmt_count(self.body)
    var si = 0
    while si < stmt_count:
        let kind = MirBody.stmt_kind(self.body, si)
        if kind == SK_ASSIGN():
            let dest = MirBody.stmt_d0(self.body, si)
            // Check if dest is borrowed
            let borrow_count = self.borrows.len() as i32
            var bi = 0
            while bi < borrow_count:
                let borrow = self.borrows.get(bi as i64)
                if borrow.local == dest:
                    let region = self.regions.get(bi as i64)
                    // Is the write inside the borrow's region?
                    // (simplified: check if any block in region is active)
                    if region.blocks.len() > 0:
                        BorrowChecker.emit_error(self, "cannot assign to borrowed value", 0, 0)
                bi = bi + 1
        si = si + 1

// ── Second-class reference enforcement ───────────────────────────────

// References cannot escape: not in struct fields, not returned, not in heap.
fn BorrowChecker.check_no_escape(self: BorrowChecker) -> void:
    let local_count = MirBody.local_count(self.body)
    var i = 0
    while i < local_count:
        let decl = MirBody.get_local(self.body, i)
        if TypeTable.is_ref(self.types, decl.type_id):
            // Check this reference doesn't escape the function
            // (simplified: check it's not stored in return place)
            if i == 0:
                BorrowChecker.emit_error(self, "references cannot be returned", decl.span_start, decl.span_end)
        i = i + 1

// ── Utility: find active borrows at a given point ────────────────────

fn BorrowChecker.active_borrows_at(self: BorrowChecker, bb: i32) -> i32:
    // Returns count of active borrows at block bb
    let borrow_count = self.borrows.len() as i32
    var active = 0
    var i = 0
    while i < borrow_count:
        let region = self.regions.get(i as i64)
        if NllRegion.contains(region, bb):
            active = active + 1
        i = i + 1
    active
