// MirOpt — Analysis data structures for optimization passes.
//
// STUB: The optimization passes (devirtualize, promote_non_escaping_boxes,
// eliminate_dead_fields, elide_redundant_moves) currently only count
// candidates without mutating MIR. Full transforms are not yet implemented.
//
// Defines call-site analysis, allocation tracking, field usage,
// and move analysis for devirtualization, escape analysis,
// dead-field elimination, and move elision.

// Call kinds
const CK_DYN_DISPATCH: i32 = 0
const CK_DIRECT: i32 = 1

type MirCallSite = {
    kind: i32,
    receiver_type_known: bool,
}

// Allocation kinds
const AK_BOX: i32 = 0
const AK_STACK: i32 = 1

type MirAllocation = {
    kind: i32,
    escapes: bool,
}

type MirField = {
    name: str,
    read_count: i32,
    removed: bool,
}

type MirMove = {
    source_consumed_immediately: bool,
    elided: bool,
}

type MirOptFunction = {
    name: str,
    calls: Vec[MirCallSite],
    allocations: Vec[MirAllocation],
    moves: Vec[MirMove],
}

fn MirOptFunction.init(name: str) -> MirOptFunction:
    MirOptFunction {
        name,
        calls: Vec.new(),
        allocations: Vec.new(),
        moves: Vec.new(),
    }

type MirOptTypeDecl = {
    name: str,
    fields: Vec[MirField],
}

fn MirOptTypeDecl.init(name: str) -> MirOptTypeDecl:
    MirOptTypeDecl {
        name,
        fields: Vec.new(),
    }

type MirOptModule = {
    functions: Vec[MirOptFunction],
    types: Vec[MirOptTypeDecl],
}

fn MirOptModule.init -> MirOptModule:
    MirOptModule {
        functions: Vec.new(),
        types: Vec.new(),
    }

// No-op: reserved for future manual memory management.
fn MirOptModule.deinit(self: MirOptModule):
    return

fn MirOptModule.add_function(self: MirOptModule, name: str) -> i32:
    let idx = self.functions.len() as i32
    self.functions.push(MirOptFunction.init(name))
    idx

fn MirOptModule.add_type(self: MirOptModule, name: str) -> i32:
    let idx = self.types.len() as i32
    self.types.push(MirOptTypeDecl.init(name))
    idx

type OptSummary = {
    devirtualized_calls: i32,
    stack_promoted_boxes: i32,
    removed_fields: i32,
    elided_moves: i32,
}

fn optimize(mod: MirOptModule) -> OptSummary:
    let dev = devirtualize(mod)
    let promo = promote_non_escaping_boxes(mod)
    let dead = eliminate_dead_fields(mod)
    let elided = elide_redundant_moves(mod)
    OptSummary {
        devirtualized_calls: dev,
        stack_promoted_boxes: promo,
        removed_fields: dead,
        elided_moves: elided,
    }

fn devirtualize(mod: MirOptModule) -> i32:
    var changed = 0
    for fi in 0..mod.functions.len() as i32:
        let func = mod.functions.get(fi as i64)
        for ci in 0..func.calls.len() as i32:
            let call = func.calls.get(ci as i64)
            if call.kind == CK_DYN_DISPATCH and call.receiver_type_known:
                // Devirtualize: rewrite to direct call
                // Note: would need mutable access in real implementation
                changed = changed + 1
    changed

fn promote_non_escaping_boxes(mod: MirOptModule) -> i32:
    var changed = 0
    for fi in 0..mod.functions.len() as i32:
        let func = mod.functions.get(fi as i64)
        for ai in 0..func.allocations.len() as i32:
            let alloc = func.allocations.get(ai as i64)
            if alloc.kind == AK_BOX and not alloc.escapes:
                changed = changed + 1
    changed

fn eliminate_dead_fields(mod: MirOptModule) -> i32:
    var changed = 0
    for ti in 0..mod.types.len() as i32:
        let ty = mod.types.get(ti as i64)
        for fi in 0..ty.fields.len() as i32:
            let field = ty.fields.get(fi as i64)
            if not field.removed and field.read_count == 0:
                changed = changed + 1
    changed

fn elide_redundant_moves(mod: MirOptModule) -> i32:
    var changed = 0
    for fi in 0..mod.functions.len() as i32:
        let func = mod.functions.get(fi as i64)
        for mi in 0..func.moves.len() as i32:
            let mv = func.moves.get(mi as i64)
            if not mv.elided and mv.source_consumed_immediately:
                changed = changed + 1
    changed
