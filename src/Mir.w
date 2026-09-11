// Semantic-analysis adapters and named MIR diagnostics.
// The data model and ownership validator live in MirCore without Sema/LLVM.
use MirCore
use Sema

impl MirModule:
    mut fn snapshot_sema_types(sema: &Sema):
        for i in 0..sema.type_kinds.len():
            self.sema_type_kinds.push(sema.type_kinds[i])
        for i in 0..sema.type_d0.len():
            self.sema_type_d0.push(sema.type_d0[i])
        for i in 0..sema.type_d1.len():
            self.sema_type_d1.push(sema.type_d1[i])
        for i in 0..sema.type_d2.len():
            self.sema_type_d2.push(sema.type_d2[i])
        for i in 0..sema.type_extra.len():
            self.sema_type_extra.push(sema.type_extra[i])
        // Deep-copy like the type-table Vecs above: assigning the handle would
        // leave sema and this module as two owners of one map, and both drop.
        let bitpacked_tids = sema.bitpacked_types.keys()
        for i in 0..bitpacked_tids.len():
            let tid = bitpacked_tids[i]
            self.sema_bitpacked_types.insert(tid, sema.bitpacked_types.get(tid).unwrap())
        let disc_repr_tids = sema.disc_repr_types.keys()
        for i in 0..disc_repr_tids.len():
            let tid = disc_repr_tids[i]
            self.sema_disc_repr_types.insert(tid, sema.disc_repr_types.get(tid).unwrap())
        let distinct_type_syms = sema.distinct_type_names.keys()
        for i in 0..distinct_type_syms.len():
            let sym = distinct_type_syms[i]
            self.sema_distinct_type_names.insert(sym, sema.distinct_type_names.get(sym).unwrap())
        if sema.type_symbol_is_std_box(sema.syms.box) != 0:
            self.sema_box_sym = sema.syms.box
            self.sema_option_sym = sema.syms.option


fn MirBody.init(fn_sym: i32, sema: &Sema) -> MirBody:
    var body = MirBody.init_for_fn(fn_sym)
    if sema.ty_void != 0:
        body.local_type_ids[0] = sema.ty_void
    body


fn dump_mir_module(mir_mod: &MirModule, pool: &InternPool, sema: &Sema) -> str:
    var out = ""
    out = out ++ f"mir module functions={mir_mod.bodies.len() as i32}\n"
    for i in 0..mir_mod.bodies.len():
        if i > 0:
            out = out ++ "\n"
        let body = &mir_mod.bodies[i]
        out = out ++ dump_mir_body(body, pool, sema)
    out

// Streaming variant of dump_mir_module to avoid quadratic whole-module
// concatenation when dumping large MIR corpora.

fn print_mir_module(mir_mod: &MirModule, pool: &InternPool, sema: &Sema):
    with_write(f"mir module functions={mir_mod.bodies.len() as i32}\n")
    for i in 0..mir_mod.bodies.len():
        if i > 0:
            with_write("\n")
        let body = &mir_mod.bodies[i]
        with_write(dump_mir_body(body, pool, sema))


pub fn dump_mir_body(body: &MirBody, pool: &InternPool, sema: &Sema) -> str:
    var out = ""
    let fn_name = if body.fn_sym != 0:
        f"sym{body.fn_sym}({pool.resolve(body.fn_sym)})"
    else:
        "<anon>"
    out = out ++ "fn " ++ fn_name ++ " " ++ lbrace() ++ "\n"
    out = out ++ "  locals:\n"

    let local_total = body.local_type_ids.len() as i32
    let bb_total = body.bb_stmt_starts.len() as i32
    let stmt_total = body.stmt_kinds.len() as i32
    if local_total > 50000 or bb_total > 20000 or stmt_total > 500000:
        out = out ++ f"    <mir dump omitted: body too large locals={local_total} bbs={bb_total} stmts={stmt_total}>\n"
        out = out ++ rbrace() ++ "\n"
        return out

    var local_count = local_total
    if local_count > 1024:
        local_count = 1024
    for li in 0..local_count:
        let tid = body.local_type_ids[li]
        let ty_name = if tid != 0: f"ty{tid}" else: "<inferred>"
        var line = f"    _{li}: " ++ ty_name
        if li == 0:
            line = line ++ "  // return"
        let name_sym = body.local_names[li]
        if body.local_is_user_var[li] != 0 and name_sym != 0:
            line = line ++ f"  // sym{name_sym}"
        if body.local_is_global[li] != 0:
            line = line ++ " [global]"
        if body.local_mutables[li] != 0:
            line = line ++ " [mut]"
        out = out ++ line ++ "\n"
    if local_total > local_count:
        out = out ++ f"    ... locals truncated ({local_total - local_count} more)\n"

    var bb_count = bb_total
    if bb_count > 512:
        bb_count = 512
    for bb in 0..bb_count:
        out = out ++ "\n"
        out = out ++ f"  bb{bb}: " ++ lbrace() ++ "\n"

        let stmt_start = body.bb_stmt_starts[bb]
        let raw_stmt_count = body.bb_stmt_counts[bb]
        var stmt_count: i32 = raw_stmt_count
        if stmt_start < 0 or raw_stmt_count < 0 or stmt_start > stmt_total:
            out = out ++ "    <invalid statement span>\n"
            stmt_count = 0
        else if stmt_start + raw_stmt_count > stmt_total:
            stmt_count = stmt_total - stmt_start
            out = out ++ "    <statement span truncated>\n"
        if stmt_count > 2048:
            stmt_count = 2048
            out = out ++ "    <statement dump capped>\n"
        for si in 0..stmt_count:
            let stmt_id = stmt_start + si
            out = out ++ "    " ++ mir_stmt_text(body, stmt_id, pool, sema) ++ "\n"

        out = out ++ "    " ++ mir_term_text(body, bb, pool, sema) ++ "\n"
        out = out ++ "  " ++ rbrace() ++ "\n"
    if bb_total > bb_count:
        out = out ++ f"\n  ... blocks truncated ({bb_total - bb_count} more)\n"

    out = out ++ rbrace() ++ "\n"
    out


fn mir_stmt_text(body: &MirBody, stmt_id: i32, pool: &InternPool, sema: &Sema) -> str:
    let kind = body.stmt_kind(stmt_id)
    let d0 = body.stmt_data0(stmt_id)
    let d1 = body.stmt_data1(stmt_id)

    if kind == StmtKind.Assign:
        return mir_place_text_named(body, d0, pool, sema) ++ " = " ++ mir_rvalue_text(body, d1, pool, sema) ++ ";"
    if kind == StmtKind.StorageLive:
        return f"StorageLive(_{d0});"
    if kind == StmtKind.StorageDead:
        return f"StorageDead(_{d0});"
    if kind == StmtKind.Drop:
        if d1 != 0:
            return "drop(" ++ mir_place_text_named(body, d0, pool, sema) ++ ") @ " ++ pool.resolve(d1) ++ ";"
        return "drop(" ++ mir_place_text_named(body, d0, pool, sema) ++ ");"
    if kind == StmtKind.Nop:
        return "nop;"

    f"stmt<{kind}>({d0}, {d1});"


fn mir_term_text(body: &MirBody, bb: i32, pool: &InternPool, sema: &Sema) -> str:
    let kind = body.term_kind(bb)
    let d0 = body.term_data0(bb)
    let d1 = body.term_data1(bb)
    let d2 = body.term_data2(bb)
    let d3 = body.term_data3(bb)

    if kind == TermKind.TK_GOTO:
        return f"goto -> bb{d0};"

    if kind == TermKind.TK_RETURN:
        return "return;"

    if kind == TermKind.TK_UNREACHABLE:
        return "unreachable;"

    if kind == TermKind.TK_SWITCH_INT:
        let op_text = mir_operand_text(body, d0, pool, sema)
        var table_text = ""
        if d1 >= 0 and d1 < body.switch_table_starts.len():
            let start = body.switch_table_starts[d1]
            let raw_count = body.switch_table_counts[d1]
            var count: i32 = raw_count
            let vals_len = body.switch_table_vals.len() as i32
            let tgts_len = body.switch_table_targets.len() as i32
            if start < 0 or raw_count < 0 or start > vals_len or start > tgts_len:
                count = 0
                table_text = "<invalid switch table>"
            else:
                let max_len = if vals_len < tgts_len: vals_len else: tgts_len
                if start + raw_count > max_len:
                    count = max_len - start
            if count > 256:
                count = 256
            for i in 0..count:
                if i > 0:
                    table_text = table_text ++ ", "
                table_text = table_text ++ f"{body.switch_table_vals[(start + i)]}"
                table_text = table_text ++ f": bb{body.switch_table_targets[(start + i)]}"
            if raw_count > count:
                if table_text.len() > 0:
                    table_text = table_text ++ ", "
                table_text = table_text ++ "..."
        if d2 != 0 or table_text.len() == 0:
            if table_text.len() > 0:
                table_text = table_text ++ ", "
            table_text = table_text ++ f"otherwise: bb{d2}"
        return "switchInt(" ++ op_text ++ ") -> [" ++ table_text ++ "];"

    if kind == TermKind.TK_CALL:
        let fn_text = mir_operand_text(body, d0, pool, sema)
        let args_text = mir_call_args_text(body, d1, pool, sema)
        let dest_text = mir_place_text_named(body, d2, pool, sema)
        return f"call {fn_text}({args_text}) -> [return: {dest_text}, next: bb{d3}];"

    if kind == TermKind.TK_DROP_AND_GOTO:
        return f"drop({mir_place_text_named(body, d0, pool, sema)}) -> bb{d1};"

    f"term<{kind}>({d0}, {d1}, {d2}, {d3});"

// Display twin of mir_place_text: renders PK_FIELD tokens as field NAMES
// (`_1.buf`, not `_1.f354`) so dump fixtures never pin pool-order-dependent
// sym ids — any stdlib intern change shifted them and flapped the phase
// lane. Token disambiguation follows tuple_index_from_field_token's rule:
// a token below the base type's field count is an index, otherwise an
// interned sym (either pool). Nested generic-inst field types degrade to
// the raw `.f{token}` spelling rather than risk the frozen query's phase
// bug in a formatter. The raw mir_place_text stays the drop-state KEY
// spelling — do not switch key/hot-path callers to this.

fn mir_place_text_named(body: &MirBody, place_id: i32, pool: &InternPool, sema: &Sema) -> str:
    if place_id < 0 or place_id >= body.place_locals.len():
        return "_?"
    let p_start = body.place_proj_starts[place_id]
    let p_count = body.place_proj_counts[place_id]
    let local = body.place_locals[place_id] as i32
    if p_count == 0:
        return mir_drop_state_local_key(local)
    var out = mir_drop_state_local_key(local)
    var cur_ty = if local >= 0 and local < body.local_type_ids.len(): body.local_type_ids[local] else: 0
    for i in 0..p_count:
        let pk = body.proj_kinds[(p_start + i)]
        let pd = body.proj_d0[(p_start + i)]
        if pk == ProjKind.PK_FIELD:
            var rendered = ""
            var next_ty = 0
            if cur_ty != 0:
                let resolved = sema.resolve_alias(cur_ty as TypeId)
                let fcount = sema.type_reflection_field_count(resolved as i32)
                if pd >= 0 and pd < fcount:
                    let fname = sema.type_reflection_field_name(resolved as i32, pd)
                    let ftext = sema.pool_resolve_symbol(fname)
                    if ftext.len() > 0:
                        rendered = "." ++ ftext
                else:
                    var ftext = pool.resolve_symbol(pd)
                    if ftext.len() == 0:
                        ftext = sema.pool_resolve_symbol(pd)
                    if ftext.len() > 0:
                        rendered = "." ++ ftext
                    if sema.get_type_kind(resolved) == TypeKind.TY_STRUCT:
                        next_ty = sema.struct_field_type_frozen(resolved as i32, pd)
            if rendered.len() == 0:
                rendered = f".f{pd}"
            out = out ++ rendered
            cur_ty = next_ty
            continue
        if pk == ProjKind.PK_TUPLE_INDEX:
            out = out ++ f".{pd}"
            cur_ty = 0
            continue
        if pk == ProjKind.PK_INDEX:
            out = out ++ f"[_{pd}]"
            cur_ty = 0
            continue
        if pk == ProjKind.PK_DEREF:
            out = out ++ ".*"
            if cur_ty != 0:
                let deref_resolved = sema.resolve_alias(cur_ty as TypeId)
                let deref_tk = sema.get_type_kind(deref_resolved)
                cur_ty = if deref_tk == TypeKind.TY_REF or deref_tk == TypeKind.TY_PTR: sema.get_type_d0(deref_resolved) else: 0
            continue
        if pk == ProjKind.PK_DOWNCAST:
            out = out ++ f"<as v{pd}>"
            cur_ty = 0
            continue
        out = out ++ f"<p{pk}:{pd}>"
        cur_ty = 0
    out


fn mir_rvalue_text(body: &MirBody, rval_id: i32, pool: &InternPool, sema: &Sema) -> str:
    if rval_id < 0 or rval_id >= body.rval_kinds.len():
        return "<rvalue?>"

    let k = body.rval_kinds[rval_id]
    let d0 = body.rval_d0[rval_id]
    let d1 = body.rval_d1[rval_id]
    let d2 = body.rval_d2[rval_id]

    if k == RvalueKind.RK_USE:
        return mir_operand_text(body, d0, pool, sema)

    if k == RvalueKind.RK_BIN_OP:
        return "binop(" ++ mir_binop_name(d0) ++ ", " ++ mir_operand_text(body, d1, pool, sema) ++ ", " ++ mir_operand_text(body, d2, pool, sema) ++ ")"

    if k == RvalueKind.RK_UN_OP:
        return "unop(" ++ mir_unop_name(d0) ++ ", " ++ mir_operand_text(body, d1, pool, sema) ++ ")"

    if k == RvalueKind.RK_REF:
        let borrow = if d0 == BorrowKind.EXCLUSIVE: "mut" else: "shared"
        return "ref(" ++ borrow ++ ", " ++ mir_place_text_named(body, d1, pool, sema) ++ ")"

    if k == RvalueKind.RK_ADDR_OF:
        return "addr_of(" ++ mir_place_text_named(body, d0, pool, sema) ++ ")"

    if k == RvalueKind.RK_AGGREGATE:
        return f"aggregate(kind={d0}, tag={d2}, fields=[{mir_agg_fields_text(body, d1, pool, sema)}])"

    if k == RvalueKind.RK_DISCRIMINANT:
        return "discriminant(" ++ mir_place_text_named(body, d0, pool, sema) ++ ")"

    if k == RvalueKind.RK_CAST:
        let ty = if d1 != 0: f"ty{d1}" else: "<inferred>"
        return "cast(" ++ mir_operand_text(body, d0, pool, sema) ++ " as " ++ ty ++ ")"

    if k == RvalueKind.RK_LEN:
        return "len(" ++ mir_place_text_named(body, d0, pool, sema) ++ ")"

    if k == RvalueKind.RK_ARRAY_FILL:
        return f"array_fill({mir_operand_text(body, d0, pool, sema)}, count={d1})"

    if k == RvalueKind.RK_STR_CONCAT_N:
        return f"str_concat_n([{mir_call_args_text(body, d0, pool, sema)}])"

    if k == RvalueKind.RK_SLICE:
        return "slice(" ++ mir_place_text_named(body, d0, pool, sema) ++ ", " ++ mir_operand_text(body, d1, pool, sema) ++ ", " ++ mir_operand_text(body, d2, pool, sema) ++ ")"

    return f"rvalue<{k}>({d0}, {d1}, {d2})"


fn mir_operand_text(body: &MirBody, operand_id: i32, pool: &InternPool, sema: &Sema) -> str:
    if operand_id < 0 or operand_id >= body.operand_kinds.len():
        return "<op?>"

    let k = body.operand_kinds[operand_id]
    let d0 = body.operand_d0[operand_id]

    if k == OperandKind.OK_COPY:
        return "copy " ++ mir_place_text_named(body, d0, pool, sema)
    if k == OperandKind.OK_MOVE:
        return "move " ++ mir_place_text_named(body, d0, pool, sema)
    if k == OperandKind.OK_CONSTANT:
        return mir_const_text(body, d0, pool, sema)

    f"op<{k}>({d0})"


fn mir_const_text(body: &MirBody, const_id: i32, pool: &InternPool, sema: &Sema) -> str:
    if const_id < 0 or const_id >= body.const_kinds.len():
        return "const<?>"

    let k = body.const_kinds[const_id]
    let d0 = body.const_d0[const_id]
    let ty = body.const_types[const_id]

    if k == ConstKind.CK_INT:
        let ty_name = if ty != 0: f"ty{ty}" else: "i32"
        return f"const {with_i64_to_str(mir_const_int_value(body, const_id))}{ty_name}"

    if k == ConstKind.CK_INT_EXACT:
        let ty_name = if ty != 0: f"ty{ty}" else: "int"
        return "const " ++ mir_exact_int_text(sema.ast, d0) ++ ty_name

    if k == ConstKind.CK_BOOL:
        return if d0 != 0: "const true" else: "const false"

    if k == ConstKind.CK_STR:
        if d0 == 0:
            return "const \"\""
        return f"const \"sym{d0}\""

    if k == ConstKind.CK_C_STR:
        if d0 == 0:
            return "const c\"\""
        return f"const c\"sym{d0}\""

    if k == ConstKind.CK_UNIT:
        return "const ()"

    if k == ConstKind.CK_FLOAT:
        if d0 != 0:
            return f"const sym{d0}"
        return "const 0.0"

    if k == ConstKind.CK_ZERO_SIZED:
        let ty_name = if ty != 0: f"ty{ty}" else: "<zst>"
        return "const zst(" ++ ty_name ++ ")"

    if k == ConstKind.CK_FN:
        if d0 != 0:
            return f"const fn sym{d0}"
        return "const fn <unknown>"

    if k == ConstKind.CK_CLOSURE:
        return f"const closure(node{d0})"

    if k == ConstKind.CK_ASYNC_BLOCK:
        return f"const async_block(node{d0})"

    if k == ConstKind.CK_REGEX_LIT:
        return f"const regex(sym{d0}, flags=sym{body.const_d1[const_id]}, node{body.const_d2[const_id]})"

    f"const<{k}>({d0})"


fn mir_agg_fields_text(body: &MirBody, fields_id: i32, pool: &InternPool, sema: &Sema) -> str:
    if fields_id < 0 or fields_id >= body.agg_field_starts.len():
        return ""

    let start = body.agg_field_starts[fields_id]
    let raw_count = body.agg_field_counts[fields_id]
    let ops_len = body.agg_field_operands.len() as i32
    if start < 0 or raw_count < 0 or start > ops_len:
        return "<invalid aggregate fields>"
    let count = if start + raw_count > ops_len: ops_len - start else: raw_count
    let capped = if count > 256: 256 else: count
    var out = ""
    for i in 0..capped:
        if i > 0:
            out = out ++ ", "
        out = out ++ mir_operand_text(body, body.agg_field_operands[(start + i)], pool, sema)
    if raw_count > capped:
        if out.len() > 0:
            out = out ++ ", "
        out = out ++ "..."
    out


fn mir_call_args_text(body: &MirBody, args_id: i32, pool: &InternPool, sema: &Sema) -> str:
    if args_id < 0 or args_id >= body.call_arg_starts.len():
        return ""

    let start = body.call_arg_starts[args_id]
    let raw_count = body.call_arg_counts[args_id]
    let ops_len = body.call_arg_operands.len() as i32
    if start < 0 or raw_count < 0 or start > ops_len:
        return "<invalid call args>"
    let count = if start + raw_count > ops_len: ops_len - start else: raw_count
    let capped = if count > 256: 256 else: count
    var out = ""
    for i in 0..capped:
        if i > 0:
            out = out ++ ", "
        out = out ++ mir_operand_text(body, body.call_arg_operands[(start + i)], pool, sema)
    if raw_count > capped:
        if out.len() > 0:
            out = out ++ ", "
        out = out ++ "..."
    out

// ── Drop-state dump (--dump-drop-state) ──────────────────────────


fn dump_drop_state_module(mir_mod: &MirModule, pool: &InternPool, sema: &Sema) -> str:
    let _ = sema
    var out = f"drop-state module functions={mir_mod.bodies.len() as i32}\n"
    for i in 0..mir_mod.bodies.len():
        if i > 0:
            out = out ++ "\n"
        let body = &mir_mod.bodies[i]
        out = out ++ dump_drop_state_body(body, pool)
    out


fn trace_ownership_body(body: &MirBody, pool: &InternPool, sema: &Sema, spec: &str, target: &str) -> str:
    var out = ""
    out = out ++ "fn " ++ mir_debug_body_label(body, pool) ++ "\n"
    var hits = 0
    let blocks = mir_drop_state_compute_blocks(body)
    for bb in 0..body.block_count():
        var state = blocks.input(body, bb)
        let stmt_start = body.bb_stmt_starts[bb]
        let stmt_count = body.bb_stmt_counts[bb]
        for si in 0..stmt_count:
            let stmt_id = stmt_start + si
            let before = state.selected_format(blocks.keys, target)
            let text = mir_stmt_text(body, stmt_id, pool, sema)
            let event = mir_ownership_stmt_event(body, stmt_id, target)
            state.transfer_stmt(blocks.keys, body, stmt_id)
            let after = state.selected_format(blocks.keys, target)
            if before != after or mir_debug_mentions(text, target):
                out = out ++ f"  bb{bb}.stmt{stmt_id} event={event} before=" ++ before ++ " after=" ++ after ++ " text=\"" ++ text ++ "\"\n"
                hits = hits + 1
        let before_term = state.selected_format(blocks.keys, target)
        let term_text = mir_term_text(body, bb, pool, sema)
        let term_event = mir_ownership_term_event(body, bb, target)
        state.transfer_term(blocks.keys, body, bb)
        let after_term = state.selected_format(blocks.keys, target)
        if before_term != after_term or mir_debug_mentions(term_text, target):
            out = out ++ f"  bb{bb}.term event={term_event} before=" ++ before_term ++ " after=" ++ after_term ++ " text=\"" ++ term_text ++ "\"\n"
            hits = hits + 1
    if hits == 0:
        out = out ++ "  <no ownership transitions>\n"
    out


fn trace_ownership_module(mir_mod: &MirModule, pool: &InternPool, sema: &Sema, spec: &str) -> str:
    let wanted_fn = mir_debug_spec_fn(spec)
    let target = mir_debug_spec_target(spec)
    var out = "trace-ownership " ++ spec ++ "\n"
    var hits = 0
    for bi in 0..mir_mod.bodies.len():
        let body = &mir_mod.bodies[bi]
        if not mir_debug_body_matches(body, pool, wanted_fn):
            continue
        out = out ++ trace_ownership_body(body, pool, sema, spec, target)
        hits = hits + 1
    if hits == 0:
        out = out ++ "  <no matching function>\n"
    out


fn mir_drop_plan_place_line(body: &MirBody, pool: &InternPool, sema: &Sema, place_id: i32, state: i32, label: &str, text: &str) -> str:
    let ty = if place_id >= 0 and place_id < body.place_sema_types.len(): body.place_sema_types[place_id] else: 0
    label ++ " place=" ++ mir_place_text(body, place_id) ++ f" ty=ty{ty} state_before=" ++ mir_drop_state_name(state) ++ " action=" ++ mir_drop_plan_action(state) ++ " text=\"" ++ text ++ "\"\n"


fn dump_drop_plan_body(body: &MirBody, pool: &InternPool, sema: &Sema) -> str:
    var out = "fn " ++ mir_debug_body_label(body, pool) ++ "\n"
    var hits = 0
    let blocks = mir_drop_state_compute_blocks(body)
    for bb in 0..body.block_count():
        var state = blocks.input(body, bb)
        let stmt_start = body.bb_stmt_starts[bb]
        let stmt_count = body.bb_stmt_counts[bb]
        for si in 0..stmt_count:
            let stmt_id = stmt_start + si
            let kind = body.stmt_kind(stmt_id)
            if kind == StmtKind.Drop:
                let place_id = body.stmt_data0(stmt_id)
                out = out ++ mir_drop_plan_place_line(body, pool, sema, place_id, state.place(blocks.keys, place_id), f"  bb{bb}.stmt{stmt_id}", mir_stmt_text(body, stmt_id, pool, sema))
                hits = hits + 1
            else if kind == StmtKind.StorageDead:
                let local_key = mir_drop_state_local_key(body.stmt_data0(stmt_id))
                out = out ++ f"  bb{bb}.stmt{stmt_id} storage-dead local=" ++ local_key ++ " remaining=" ++ state.selected_format(blocks.keys, local_key) ++ "\n"
                hits = hits + 1
            state.transfer_stmt(blocks.keys, body, stmt_id)
        if body.term_kind(bb) == TermKind.TK_DROP_AND_GOTO:
            let place_id = body.term_data0(bb)
            out = out ++ mir_drop_plan_place_line(body, pool, sema, place_id, state.place(blocks.keys, place_id), f"  bb{bb}.term", mir_term_text(body, bb, pool, sema))
            hits = hits + 1
        state.transfer_term(blocks.keys, body, bb)
    if hits == 0:
        out = out ++ "  <no drop sites>\n"
    out


fn dump_drop_plan_module(mir_mod: &MirModule, pool: &InternPool, sema: &Sema) -> str:
    var out = f"drop-plan module functions={mir_mod.bodies.len() as i32}\n"
    for i in 0..mir_mod.bodies.len():
        if i > 0:
            out = out ++ "\n"
        let body = &mir_mod.bodies[i]
        out = out ++ dump_drop_plan_body(body, pool, sema)
    out

// Drop elaboration — the "Dead" arm (#614, docs/drop-elaboration-soundness.md).
// A `StmtKind.Drop` whose place is statically `Moved` at that point is provably
// dead: the value was moved out, so emitting the drop double-drops it. Rewrite it
// to `StmtKind.Nop` (codegen already treats Nop as a no-op). This is the analogue
// of rustc's `DropStyle::Dead` in `elaborate_drops`.
//
// `Init` drops are left unchanged (always drop — correct). `Maybe` (conditional)
// drops are left unchanged: their runtime drop-flag / branch structure (the M7
// conditional-move feature) already gates them, and Nopping them would leak.
//
// The decision is computed read-only first — using the exact dataflow walk the
// `--dump-drop-plan` diagnostic rides on — so the transfer functions observe the
// original drops; the Nops are applied afterward.

fn dump_place_map_module(mir_mod: &MirModule, pool: &InternPool, sema: &Sema) -> str:
    let _ = sema
    var out = f"place-map module functions={mir_mod.bodies.len() as i32}\n"
    for i in 0..mir_mod.bodies.len():
        if i > 0:
            out = out ++ "\n"
        let body = &mir_mod.bodies[i]
        out = out ++ dump_place_map_body(mir_mod, body, pool)
    out


fn trace_cleanup_edge_module(mir_mod: &MirModule, pool: &InternPool, sema: &Sema, spec: &str) -> str:
    let wanted_fn = mir_debug_spec_fn(spec)
    let target = mir_debug_spec_target(spec)
    let from_bb = mir_cleanup_edge_from(target)
    let to_bb = mir_cleanup_edge_to(target)
    var out = "trace-cleanup-edge " ++ spec ++ "\n"
    if from_bb < 0 or to_bb < 0:
        return out ++ "  <invalid edge spec; expected fn:from->to>\n"
    var hits = 0
    for bi in 0..mir_mod.bodies.len():
        let body = &mir_mod.bodies[bi]
        if not mir_debug_body_matches(body, pool, wanted_fn):
            continue
        if from_bb >= body.block_count() or to_bb >= body.block_count():
            continue
        if not mir_drop_state_block_has_successor(body, from_bb, to_bb):
            continue
        let blocks = mir_drop_state_compute_blocks(body)
        let from_out = blocks.load_block(from_bb)
        let to_in = blocks.input(body, to_bb)
        out = out ++ "fn " ++ mir_debug_body_label(body, pool) ++ f" edge=bb{from_bb}->bb{to_bb}\n"
        out = out ++ "  from_out: " ++ from_out.format(blocks.keys) ++ "\n"
        out = out ++ "  to_in: " ++ to_in.format(blocks.keys) ++ "\n"
        out = out ++ "  term: " ++ mir_term_text(body, from_bb, pool, sema) ++ "\n"
        if body.term_kind(from_bb) == TermKind.TK_DROP_AND_GOTO and body.term_data1(from_bb) == to_bb:
            let place_id = body.term_data0(from_bb)
            out = out ++ "  edge_drop: " ++ mir_drop_plan_place_line(body, pool, sema, place_id, from_out.place(blocks.keys, place_id), f"bb{from_bb}.term", mir_term_text(body, from_bb, pool, sema))
        hits = hits + 1
    if hits == 0:
        out = out ++ "  <no matching cleanup edge>\n"
    out


fn trace_place_module(mir_mod: &MirModule, pool: &InternPool, sema: &Sema, spec: &str) -> str:
    let wanted_fn = mir_debug_spec_fn(spec)
    let target = mir_debug_spec_target(spec)
    var out = "trace-place " ++ spec ++ "\n"
    var hits = 0
    for bi in 0..mir_mod.bodies.len():
        let body = &mir_mod.bodies[bi]
        if not mir_debug_body_matches(body, pool, wanted_fn):
            continue
        var body_header_emitted = false
        for bb in 0..body.block_count():
            let stmt_start = body.bb_stmt_starts[bb]
            let stmt_count = body.bb_stmt_counts[bb]
            for si in 0..stmt_count:
                let stmt_id = stmt_start + si
                let text = mir_stmt_text(body, stmt_id, pool, sema)
                if mir_debug_mentions(text, target):
                    if not body_header_emitted:
                        out = out ++ "fn " ++ mir_debug_body_label(body, pool) ++ "\n"
                        body_header_emitted = true
                    out = out ++ f"  bb{bb}.stmt{stmt_id}: " ++ text ++ "\n"
                    hits = hits + 1
            let term_text = mir_term_text(body, bb, pool, sema)
            if mir_debug_mentions(term_text, target):
                if not body_header_emitted:
                    out = out ++ "fn " ++ mir_debug_body_label(body, pool) ++ "\n"
                    body_header_emitted = true
                out = out ++ f"  bb{bb}.term: " ++ term_text ++ "\n"
                hits = hits + 1
    if hits == 0:
        out = out ++ "  <no matching MIR events>\n"
    out


fn explain_mir_origin_module(mir_mod: &MirModule, pool: &InternPool, sema: &Sema, spec: &str) -> str:
    let wanted_fn = mir_debug_spec_fn(spec)
    let target = mir_debug_spec_target(spec)
    var out = "mir-origin " ++ spec ++ "\n"
    var hits = 0
    for bi in 0..mir_mod.bodies.len():
        let body = &mir_mod.bodies[bi]
        if not mir_debug_body_matches(body, pool, wanted_fn):
            continue
        for li in 0..body.local_count():
            let local_label = f"_{li}"
            if mir_debug_mentions(local_label, target):
                out = out ++ "fn " ++ mir_debug_body_label(body, pool) ++ f" local _{li}"
                let info = body.get_local(li)
                out = out ++ f" type=ty{info.type_id}"
                if info.name_sym != 0:
                    out = out ++ " name=" ++ pool.resolve(info.name_sym)
                out = out ++ "\n"
                hits = hits + 1
        for bb in 0..body.block_count():
            let stmt_start = body.bb_stmt_starts[bb]
            let stmt_count = body.bb_stmt_counts[bb]
            for si in 0..stmt_count:
                let stmt_id = stmt_start + si
                let text = mir_stmt_text(body, stmt_id, pool, sema)
                let span = body.stmt_spans[stmt_id]
                if mir_debug_mentions(text, target) or target == f"stmt{stmt_id}":
                    out = out ++ "fn " ++ mir_debug_body_label(body, pool) ++ f" bb{bb}.stmt{stmt_id} span={span}: " ++ text ++ "\n"
                    hits = hits + 1
            let term_text = mir_term_text(body, bb, pool, sema)
            let term_span = body.bb_term_spans[bb]
            if mir_debug_mentions(term_text, target) or target == f"term{bb}":
                out = out ++ "fn " ++ mir_debug_body_label(body, pool) ++ f" bb{bb}.term span={term_span}: " ++ term_text ++ "\n"
                hits = hits + 1
    if hits == 0:
        out = out ++ "  <no matching MIR origin>\n"
    out

// Use-after-kill (#719 class): a local that has been killed — StorageDead, or
// blanked by a reset-on-move `_x = <zero>` — must not be read again before it is
// re-initialized. A body that does read it computes from zeroed storage; #719 is
// exactly this (a binding killed by an inner scope pop, then consumed by a later
// aggregate). Scanning blocks in index order only reports a kill that DOMINATES
// the use in the emitted order, which is the shape lowering bugs produce; a use
// reached only by a back edge is never flagged.

