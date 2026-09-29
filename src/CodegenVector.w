// CodegenVector — LLVM lowering of §4.3d SIMD vectors (D78, #1874).
//
// Sema decided each fact and MIR placed it (SemaVector.w, MirVector.w);
// this decides how: a Vector[N, T] is LLVM `<N x T>`, a Mask[N, W] is
// `<N x iW>` holding all-ones or zero per lane (what `select` and the
// hardware compare produce). Integer lanes follow §4.2 per lane: checked
// arithmetic panics when any lane overflows, unless the build's overflow
// mode or the operator (`+%`, `+|`) says otherwise.

use Codegen
use Ast
use Mir
use MirCore
use Sema
use SemaTypes
use Overflow
use compiler.LlvmBridge.*

impl Codegen:
    // The sema type's lane kind facts, read from the MIR snapshot.
    fn cg_vector_lane_sema(vec_sema: i32) -> i32:
        let resolved = self.mir_resolve_alias_at(vec_sema)
        if self.mir_type_kind_at(resolved) != TypeKind.TY_VECTOR: return 0
        self.mir_type_d0_at(resolved)

    fn cg_sema_is_vector(sema_ty: i32) -> bool:
        sema_ty > 0 and self.mir_type_kind_at(self.mir_resolve_alias_at(sema_ty)) == TypeKind.TY_VECTOR

    fn cg_sema_is_vector_or_mask(sema_ty: i32) -> bool:
        if sema_ty <= 0: return false
        let tk = self.mir_type_kind_at(self.mir_resolve_alias_at(sema_ty))
        tk == TypeKind.TY_VECTOR or tk == TypeKind.TY_MASK

    fn cg_lane_is_float(lane_sema: i32) -> bool:
        self.mir_type_kind_at(self.mir_resolve_alias_at(lane_sema)) == TypeKind.TY_FLOAT

    fn cg_lane_is_unsigned(lane_sema: i32) -> bool:
        let resolved = self.mir_resolve_alias_at(lane_sema)
        self.mir_type_kind_at(resolved) == TypeKind.TY_INT and self.mir_type_d1_at(resolved) == 0

    // A vector constant with `elem` in every one of `n` lanes.
    fn cg_splat_const(elem: i64, n: i32) -> i64:
        let vals: Vec[i64] = Vec.new()
        for _ in 0..n:
            vals.push(elem)
        wl_const_vector(vec_data_i64(&vals), n)

    // `value` in every lane of `vec_ty`.
    fn cg_splat_value(value: i64, vec_ty: i64) -> i64:
        let n = wl_get_vector_size(vec_ty)
        var out = wl_get_undef(vec_ty)
        let i32_ty = wl_i32_type(self.context)
        for i in 0..n:
            out = wl_build_insert_element(self.builder, out, value, wl_const_int(i32_ty, i as i64, 0))
        out

    // Call the overloaded LLVM intrinsic `name` at `overloads`.
    mut fn cg_vector_intrinsic(name: &str, overloads: &Vec[i64], args: &Vec[i64]) -> i64:
        let id = wl_lookup_intrinsic_id(name)
        if id == 0:
            self.had_error = 1
            self.codegen_error_detail = "missing LLVM intrinsic " ++ name
            return 0
        let fn_val = wl_get_intrinsic_decl(self.llmod, id, vec_data_i64(overloads), overloads.len() as i32)
        let fn_ty = wl_intrinsic_get_type(self.context, id, vec_data_i64(overloads), overloads.len() as i32)
        wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(args), args.len() as i32)

    // Whether any lane of a `<N x i1>` is set, as an i1.
    mut fn cg_any_lane(bits: i64) -> i64:
        let overloads: Vec[i64] = Vec.new()
        overloads.push(wl_type_of(bits))
        let args: Vec[i64] = Vec.new()
        args.push(bits)
        self.cg_vector_intrinsic("llvm.vector.reduce.or", overloads, args)

    // Branch to a panic with `msg` when any lane of `bad` (`<N x i1>`) is set.
    mut fn cg_panic_if_any_lane(bad: i64, msg: &str):
        let any = self.cg_any_lane(bad)
        let panic_bb = wl_append_bb(self.context, self.current_function, "vec.panic")
        let ok_bb = wl_append_bb(self.context, self.current_function, "vec.ok")
        wl_build_cond_br(self.builder, any, panic_bb, ok_bb)
        wl_position_at_end(self.builder, panic_bb)
        self.emit_runtime_panic(msg)
        wl_position_at_end(self.builder, ok_bb)

    // A `<N x i1>` comparison as the Mask[N, W] it yields: all ones or zero.
    fn cg_bits_to_mask(bits: i64, lane_bits: i32) -> i64:
        let n = wl_get_vector_size(wl_type_of(bits))
        wl_build_sext(self.builder, bits, wl_vector_type(wl_int_type_n(self.context, lane_bits), n))

    // A Mask's lanes as `<N x i1>`.
    fn cg_mask_to_bits(mask: i64) -> i64:
        let mask_ty = wl_type_of(mask)
        let zero = wl_const_null(mask_ty)
        wl_build_icmp(self.builder, wl_int_ne(), mask, zero)

    // The lane-wise binary operator `op` over two vectors of `vec_sema`
    // (Sema made both operands that type: a scalar arrives splatted).
    mut fn mir_build_vector_bin_op(op: i32, l: i64, r: i64, vec_sema: i32) -> i64:
        let lane = self.cg_vector_lane_sema(vec_sema)
        let vec_ty = wl_type_of(l)
        let n = wl_get_vector_size(vec_ty)
        let elem_ty = wl_get_element_type(vec_ty)
        if self.cg_lane_is_float(lane):
            let lane_bits = if wl_get_type_kind(elem_ty) == wl_float_type_kind(): 32 else: 64
            if op == BinaryOp.OP_ADD: return wl_build_fadd(self.builder, l, r)
            if op == BinaryOp.OP_SUB: return wl_build_fsub(self.builder, l, r)
            if op == BinaryOp.OP_MUL: return wl_build_fmul(self.builder, l, r)
            if op == BinaryOp.OP_DIV: return wl_build_fdiv(self.builder, l, r)
            if op == BinaryOp.OP_MOD: return wl_build_frem(self.builder, l, r)
            var pred = -1
            if op == BinaryOp.OP_EQ: pred = wl_real_oeq()
            if op == BinaryOp.OP_NEQ: pred = wl_real_une()
            if op == BinaryOp.OP_LT: pred = wl_real_olt()
            if op == BinaryOp.OP_GT: pred = wl_real_ogt()
            if op == BinaryOp.OP_LTE: pred = wl_real_ole()
            if op == BinaryOp.OP_GTE: pred = wl_real_oge()
            if pred >= 0:
                return self.cg_bits_to_mask(wl_build_fcmp(self.builder, pred, l, r), lane_bits)
            return self.cg_vector_unsupported("float vector operator")
        let unsigned = self.cg_lane_is_unsigned(lane)
        let width = wl_get_int_type_width(elem_ty)
        var ipred = -1
        if op == BinaryOp.OP_EQ: ipred = wl_int_eq()
        if op == BinaryOp.OP_NEQ: ipred = wl_int_ne()
        if op == BinaryOp.OP_LT: ipred = if unsigned: wl_int_ult() else: wl_int_slt()
        if op == BinaryOp.OP_GT: ipred = if unsigned: wl_int_ugt() else: wl_int_sgt()
        if op == BinaryOp.OP_LTE: ipred = if unsigned: wl_int_ule() else: wl_int_sle()
        if op == BinaryOp.OP_GTE: ipred = if unsigned: wl_int_uge() else: wl_int_sge()
        if ipred >= 0:
            return self.cg_bits_to_mask(wl_build_icmp(self.builder, ipred, l, r), width)
        if op == BinaryOp.OP_BIT_AND: return wl_build_and(self.builder, l, r)
        if op == BinaryOp.OP_BIT_OR: return wl_build_or(self.builder, l, r)
        if op == BinaryOp.OP_BIT_XOR: return wl_build_xor(self.builder, l, r)
        if op == BinaryOp.OP_SHL or op == BinaryOp.OP_SHR:
            // The scalar total-shift rule per lane: a count of the width or
            // more shifts every bit out (a signed right shift fills with the
            // sign).
            let limit = self.cg_splat_const(wl_const_int(elem_ty, width as i64, 0), n)
            let too_big = wl_build_icmp(self.builder, wl_int_uge(), r, limit)
            let masked = wl_build_and(self.builder, r, self.cg_splat_const(wl_const_int(elem_ty, (width - 1) as i64, 0), n))
            if op == BinaryOp.OP_SHL:
                return wl_build_select(self.builder, too_big, wl_const_null(vec_ty), wl_build_shl(self.builder, l, masked))
            if unsigned:
                return wl_build_select(self.builder, too_big, wl_const_null(vec_ty), wl_build_lshr(self.builder, l, masked))
            let sign_fill = wl_build_ashr(self.builder, l, self.cg_splat_const(wl_const_int(elem_ty, (width - 1) as i64, 0), n))
            return wl_build_select(self.builder, too_big, sign_fill, wl_build_ashr(self.builder, l, masked))
        if op == BinaryOp.OP_ADD_WRAP: return wl_build_add(self.builder, l, r)
        if op == BinaryOp.OP_SUB_WRAP: return wl_build_sub(self.builder, l, r)
        if op == BinaryOp.OP_MUL_WRAP: return wl_build_mul(self.builder, l, r)
        let base_op = if op == BinaryOp.OP_ADD_SAT: BinaryOp.OP_ADD else if op == BinaryOp.OP_SUB_SAT: BinaryOp.OP_SUB else if op == BinaryOp.OP_MUL_SAT: BinaryOp.OP_MUL else: op
        let saturating = op == BinaryOp.OP_ADD_SAT or op == BinaryOp.OP_SUB_SAT or op == BinaryOp.OP_MUL_SAT
        if base_op == BinaryOp.OP_ADD or base_op == BinaryOp.OP_SUB or base_op == BinaryOp.OP_MUL:
            if not saturating and self.overflow_mode == OVERFLOW_MODE_WRAP():
                if base_op == BinaryOp.OP_ADD: return wl_build_add(self.builder, l, r)
                if base_op == BinaryOp.OP_SUB: return wl_build_sub(self.builder, l, r)
                return wl_build_mul(self.builder, l, r)
            if saturating or self.overflow_mode == OVERFLOW_MODE_SATURATE():
                return self.cg_vector_saturating(base_op, l, r, unsigned)
            let name = self.mir_checked_overflow_intrinsic_name(base_op, unsigned)
            let overloads: Vec[i64] = Vec.new()
            overloads.push(vec_ty)
            let args: Vec[i64] = Vec.new()
            args.push(l)
            args.push(r)
            let pair = self.cg_vector_intrinsic(name, overloads, args)
            if pair == 0: return wl_get_undef(vec_ty)
            let ov_ty = (if unsigned: "u" else: "i") ++ f"{width}"
            let ov_op = if base_op == BinaryOp.OP_ADD: "addition" else if base_op == BinaryOp.OP_SUB: "subtraction" else: "multiplication"
            self.cg_panic_if_any_lane(wl_build_extract_value(self.builder, pair, 1), f"integer overflow: {ov_ty} {ov_op} out of range in a vector lane")
            return wl_build_extract_value(self.builder, pair, 0)
        if op == BinaryOp.OP_DIV or op == BinaryOp.OP_MOD:
            self.cg_panic_if_any_lane(wl_build_icmp(self.builder, wl_int_eq(), r, wl_const_null(vec_ty)), "division by zero")
            if unsigned:
                return if op == BinaryOp.OP_DIV: wl_build_udiv(self.builder, l, r) else: wl_build_urem(self.builder, l, r)
            let min_v = self.cg_splat_const(wl_const_int(elem_ty, int_signed_min(width), 1), n)
            let neg_one = self.cg_splat_const(wl_const_int(elem_ty, -1, 1), n)
            let ov = wl_build_and(self.builder, wl_build_icmp(self.builder, wl_int_eq(), l, min_v), wl_build_icmp(self.builder, wl_int_eq(), r, neg_one))
            if self.overflow_mode != OVERFLOW_MODE_WRAP() and self.overflow_mode != OVERFLOW_MODE_SATURATE():
                self.cg_panic_if_any_lane(ov, f"integer overflow: i{width} minimum divided by -1 in a vector lane")
                return if op == BinaryOp.OP_DIV: wl_build_sdiv(self.builder, l, r) else: wl_build_srem(self.builder, l, r)
            // The scalar wrap/saturate results, lane by lane, without the
            // undefined MIN / -1 division.
            let safe_r = wl_build_select(self.builder, ov, self.cg_splat_const(wl_const_int(elem_ty, 1, 0), n), r)
            let raw = if op == BinaryOp.OP_DIV: wl_build_sdiv(self.builder, l, safe_r) else: wl_build_srem(self.builder, l, safe_r)
            let ov_value = if op == BinaryOp.OP_MOD: wl_const_null(vec_ty) else if self.overflow_mode == OVERFLOW_MODE_SATURATE(): self.cg_splat_const(wl_const_int(elem_ty, int_signed_max(width), 0), n) else: min_v
            return wl_build_select(self.builder, ov, ov_value, raw)
        self.cg_vector_unsupported("integer vector operator")

    // Saturating add, subtract or multiply per lane (§4.2.3).
    mut fn cg_vector_saturating(op: i32, l: i64, r: i64, unsigned: bool) -> i64:
        let vec_ty = wl_type_of(l)
        if op == BinaryOp.OP_ADD or op == BinaryOp.OP_SUB:
            let name = if op == BinaryOp.OP_ADD: (if unsigned: "llvm.uadd.sat" else: "llvm.sadd.sat") else: (if unsigned: "llvm.usub.sat" else: "llvm.ssub.sat")
            let overloads: Vec[i64] = Vec.new()
            overloads.push(vec_ty)
            let args: Vec[i64] = Vec.new()
            args.push(l)
            args.push(r)
            return self.cg_vector_intrinsic(name, overloads, args)
        // Multiply in twice the width, clamp, truncate — the scalar rule.
        let n = wl_get_vector_size(vec_ty)
        let width = wl_get_int_type_width(wl_get_element_type(vec_ty))
        let wide_elem = wl_int_type_n(self.context, width * 2)
        let wide_ty = wl_vector_type(wide_elem, n)
        let wl2 = if unsigned: wl_build_zext(self.builder, l, wide_ty) else: wl_build_sext(self.builder, l, wide_ty)
        let wr2 = if unsigned: wl_build_zext(self.builder, r, wide_ty) else: wl_build_sext(self.builder, r, wide_ty)
        let product = wl_build_mul(self.builder, wl2, wr2)
        if unsigned:
            let max_v = self.cg_splat_const(wl_const_int(wide_elem, int_unsigned_max(width), 0), n)
            let over = wl_build_icmp(self.builder, wl_int_ugt(), product, max_v)
            return wl_build_trunc(self.builder, wl_build_select(self.builder, over, max_v, product), vec_ty)
        let max_s = self.cg_splat_const(wl_const_int(wide_elem, int_signed_max(width), 0), n)
        let min_s = self.cg_splat_const(wl_const_int(wide_elem, int_signed_min(width), 1), n)
        let hi = wl_build_select(self.builder, wl_build_icmp(self.builder, wl_int_sgt(), product, max_s), max_s, product)
        let clamped = wl_build_select(self.builder, wl_build_icmp(self.builder, wl_int_slt(), hi, min_s), min_s, hi)
        wl_build_trunc(self.builder, clamped, vec_ty)

    // `-v` and `~v` over a vector of `vec_sema`.
    mut fn mir_build_vector_un_op(op: i32, arg: i64, vec_sema: i32) -> i64:
        let lane = self.cg_vector_lane_sema(vec_sema)
        let vec_ty = wl_type_of(arg)
        if op == UnaryOp.UOP_BIT_NOT:
            return wl_build_not(self.builder, arg)
        if op != UnaryOp.UOP_NEGATE:
            return self.cg_vector_unsupported("vector unary operator")
        if self.cg_lane_is_float(lane):
            return wl_build_fneg(self.builder, arg)
        if self.overflow_mode == OVERFLOW_MODE_WRAP():
            return wl_build_neg(self.builder, arg)
        let elem_ty = wl_get_element_type(vec_ty)
        let width = wl_get_int_type_width(elem_ty)
        let n = wl_get_vector_size(vec_ty)
        let min_v = self.cg_splat_const(wl_const_int(elem_ty, int_signed_min(width), 1), n)
        let is_min = wl_build_icmp(self.builder, wl_int_eq(), arg, min_v)
        if self.overflow_mode == OVERFLOW_MODE_SATURATE():
            return wl_build_select(self.builder, is_min, self.cg_splat_const(wl_const_int(elem_ty, int_signed_max(width), 0), n), wl_build_neg(self.builder, arg))
        self.cg_panic_if_any_lane(is_min, f"integer overflow: negating i{width} minimum value in a vector lane")
        wl_build_neg(self.builder, arg)

    // `v as <vector>`: each lane converted as the scalar `as` converts it.
    mut fn mir_build_vector_cast(val: i64, src_sema: i32, dst_sema: i32) -> i64:
        let dst_ty = self.mir_sema_type_to_llvm(dst_sema)
        let src_ty = wl_type_of(val)
        if src_ty == dst_ty: return val
        let src_lane = self.cg_vector_lane_sema(src_sema)
        let dst_lane = self.cg_vector_lane_sema(dst_sema)
        let src_float = self.cg_lane_is_float(src_lane)
        let dst_float = self.cg_lane_is_float(dst_lane)
        if src_float and dst_float: return wl_build_fp_cast(self.builder, val, dst_ty)
        if src_float:
            return if self.cg_lane_is_unsigned(dst_lane): wl_build_fp_to_ui(self.builder, val, dst_ty) else: wl_build_fp_to_si(self.builder, val, dst_ty)
        if dst_float:
            return if self.cg_lane_is_unsigned(src_lane): wl_build_ui_to_fp(self.builder, val, dst_ty) else: wl_build_si_to_fp(self.builder, val, dst_ty)
        let src_w = wl_get_int_type_width(wl_get_element_type(src_ty))
        let dst_w = wl_get_int_type_width(wl_get_element_type(dst_ty))
        if dst_w < src_w: return wl_build_trunc(self.builder, val, dst_ty)
        if dst_w == src_w: return wl_build_bitcast(self.builder, val, dst_ty)
        if self.cg_lane_is_unsigned(src_lane) or self.cg_lane_is_unsigned(dst_lane):
            return wl_build_zext(self.builder, val, dst_ty)
        wl_build_sext(self.builder, val, dst_ty)

    // A constant `<N x T>` for a global's initializer: the splat Sema
    // recorded on a literal, or a construction whose lanes all fold. 0 when
    // it does not fold (the global is initialized at run time instead).
    mut fn try_eval_const_vector_llvm(node: i32, vec_tid: i32) -> i64:
        let lane = self.sema.get_type_d0(vec_tid as TypeId)
        let n = self.sema.get_type_d1(vec_tid as TypeId)
        if self.sema.vector_splats.contains(node):
            let lane_c = self.try_eval_const_llvm(node, lane)
            if lane_c == 0: return 0
            return self.cg_splat_const(lane_c, n)
        let op = self.sema.vector_ops.get(node) ?? 0
        if op != VectorOp.CONSTRUCT as i32 and op != VectorOp.SPLAT as i32:
            return 0
        let extra_start = self.pool.get_data1(node)
        let vals: Vec[i64] = Vec.new()
        for i in 0..n:
            let arg = self.pool.get_extra(extra_start + (if op == VectorOp.SPLAT as i32: 0 else: i))
            let c = self.try_eval_const_llvm(arg, lane)
            if c == 0: return 0
            vals.push(c)
        wl_const_vector(vec_data_i64(&vals), n)

    // A vector aggregate: lane i from operand i.
    mut fn mir_build_vector_aggregate(body: &MirBody, start: i32, count: i32, vec_ty: i64) -> i64:
        let elem_ty = wl_get_element_type(vec_ty)
        let i32_ty = wl_i32_type(self.context)
        var out = wl_get_undef(vec_ty)
        for i in 0..count:
            let lane = self.mir_eval_operand(body, body.agg_field_operands[(start + i)], elem_ty)
            if wl_type_of(lane) != elem_ty:
                return self.cg_vector_unsupported("a vector lane operand of another type")
            out = wl_build_insert_element(self.builder, out, lane, wl_const_int(i32_ty, i as i64, 0))
        out

    // Codegen met a vector shape MIR should not have produced: a compiler
    // bug, reported (D65: post-Sema invalid MIR is loud, never guessed).
    mut fn cg_vector_unsupported(what: &str) -> i64:
        self.had_error = 1
        self.codegen_error_detail = f"code generation failed: {what} (§4.3d)"
        wl_get_undef(wl_i32_type(self.context))

    // The lane pointer of `v[i]` on a vector place: a GEP over the lane
    // type (a vector's lanes are packed), after the §4.3a range check.
    mut fn mir_vector_lane_ptr(vec_ptr: i64, vec_ty: i64, idx: i64) -> i64:
        let n = wl_get_vector_size(vec_ty)
        let i64_ty = wl_i64_type(self.context)
        let idx64 = if wl_get_int_type_width(wl_type_of(idx)) < 64: wl_build_sext(self.builder, idx, i64_ty) else: idx
        if wl_is_constant(idx64) == 0:
            let bad = wl_build_icmp(self.builder, wl_int_uge(), idx64, wl_const_int(i64_ty, n as i64, 0))
            let panic_bb = wl_append_bb(self.context, self.current_function, "lane.bounds.panic")
            let ok_bb = wl_append_bb(self.context, self.current_function, "lane.bounds.ok")
            wl_build_cond_br(self.builder, bad, panic_bb, ok_bb)
            wl_position_at_end(self.builder, panic_bb)
            self.emit_runtime_panic("index out of bounds")
            wl_position_at_end(self.builder, ok_bb)
        let indices: Vec[i64] = Vec.new()
        indices.push(idx64)
        wl_build_gep(self.builder, wl_get_element_type(vec_ty), vec_ptr, vec_data_i64(&indices), 1)

    // The SIMD_* intrinsic calls MirVector emits. False for any other.
    mut fn mir_emit_vector_intrinsic_call(body: &MirBody, intrinsic: MirIntrinsic, args_id: i32, dest_place: i32, next_bb: i32) -> bool:
        let is_simd = intrinsic == MirIntrinsic.SIMD_BITCAST or intrinsic == MirIntrinsic.SIMD_SELECT or intrinsic == MirIntrinsic.SIMD_ALL or intrinsic == MirIntrinsic.SIMD_ANY or
            intrinsic == MirIntrinsic.SIMD_REDUCE_ADD or intrinsic == MirIntrinsic.SIMD_REDUCE_MUL or intrinsic == MirIntrinsic.SIMD_REDUCE_MIN or intrinsic == MirIntrinsic.SIMD_REDUCE_MAX or
            intrinsic == MirIntrinsic.SIMD_REDUCE_AND or intrinsic == MirIntrinsic.SIMD_REDUCE_OR or intrinsic == MirIntrinsic.SIMD_REDUCE_XOR
        if not is_simd: return false
        let a = self.mir_intrinsic_arg(body, args_id, 0)
        let a_ty = wl_type_of(a)
        var result: i64 = 0
        if intrinsic == MirIntrinsic.SIMD_BITCAST:
            let dest_sema = self.mir_intrinsic_dest_sema_type(body, dest_place)
            result = wl_build_bitcast(self.builder, a, self.mir_sema_type_to_llvm(dest_sema))
        else if intrinsic == MirIntrinsic.SIMD_SELECT:
            let on = self.mir_intrinsic_arg(body, args_id, 1)
            let off = self.mir_intrinsic_arg(body, args_id, 2)
            result = wl_build_select(self.builder, self.cg_mask_to_bits(a), on, off)
        else if intrinsic == MirIntrinsic.SIMD_ALL or intrinsic == MirIntrinsic.SIMD_ANY:
            let bits = self.cg_mask_to_bits(a)
            let overloads: Vec[i64] = Vec.new()
            overloads.push(wl_type_of(bits))
            let args: Vec[i64] = Vec.new()
            args.push(bits)
            result = self.cg_vector_intrinsic(if intrinsic == MirIntrinsic.SIMD_ALL: "llvm.vector.reduce.and" else: "llvm.vector.reduce.or", overloads, args)
        else:
            let arg_start = body.call_arg_starts[args_id]
            let vec_sema = self.mir_operand_sema_type(body, body.call_arg_operands[arg_start])
            let lane = self.cg_vector_lane_sema(vec_sema)
            let is_float = self.cg_lane_is_float(lane)
            let unsigned = self.cg_lane_is_unsigned(lane)
            let elem_ty = wl_get_element_type(a_ty)
            let overloads: Vec[i64] = Vec.new()
            overloads.push(a_ty)
            let args: Vec[i64] = Vec.new()
            var name = ""
            if intrinsic == MirIntrinsic.SIMD_REDUCE_ADD or intrinsic == MirIntrinsic.SIMD_REDUCE_MUL:
                if is_float:
                    // Ordered: lane 0 first, as the scalar loop would sum.
                    name = if intrinsic == MirIntrinsic.SIMD_REDUCE_ADD: "llvm.vector.reduce.fadd" else: "llvm.vector.reduce.fmul"
                    args.push(if intrinsic == MirIntrinsic.SIMD_REDUCE_ADD: wl_const_real(elem_ty, -0.0) else: wl_const_real(elem_ty, 1.0))
                else:
                    name = if intrinsic == MirIntrinsic.SIMD_REDUCE_ADD: "llvm.vector.reduce.add" else: "llvm.vector.reduce.mul"
            else if intrinsic == MirIntrinsic.SIMD_REDUCE_MIN:
                name = if is_float: "llvm.vector.reduce.fmin" else if unsigned: "llvm.vector.reduce.umin" else: "llvm.vector.reduce.smin"
            else if intrinsic == MirIntrinsic.SIMD_REDUCE_MAX:
                name = if is_float: "llvm.vector.reduce.fmax" else if unsigned: "llvm.vector.reduce.umax" else: "llvm.vector.reduce.smax"
            else if intrinsic == MirIntrinsic.SIMD_REDUCE_AND:
                name = "llvm.vector.reduce.and"
            else if intrinsic == MirIntrinsic.SIMD_REDUCE_OR:
                name = "llvm.vector.reduce.or"
            else:
                name = "llvm.vector.reduce.xor"
            args.push(a)
            result = self.cg_vector_intrinsic(name, overloads, args)
        self.mir_finish_intrinsic_call(body, dest_place, next_bb, result)
        true
