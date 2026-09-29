// MirVector — MIR lowering of §4.3d SIMD vectors (D78, #1874).
//
// Sema decided every vector fact (Sema.vector_ops, vector_swizzles,
// vector_splats, vector_conversions; SemaVector.w). This lowers each to
// ordinary MIR: a construction, a splat or a swizzle is an RK_AGGREGATE of
// the vector type (one operand per lane), a lane-wise conversion an RK_CAST,
// and the operations with no rvalue (`select`, the reductions, `.bits()`)
// intrinsic calls. Codegen decides how each lowers to LLVM.

use Ast
use Mir
use MirCore
use MirLower
use Sema
use SemaTypes
use SemaVector

impl MirBuilder:
    // lower_expr's hook: the operand for `node` when Sema recorded a vector
    // fact for it, else -1.
    mut fn lower_vector_node(node: i32) -> i32:
        if node != self.vector_raw_node:
            if self.sema.vector_splats.contains(node):
                return self.lower_vector_splat_node(node)
            if self.sema.vector_conversions.contains(node):
                return self.lower_vector_conversion_node(node)
        if self.sema.vector_ops.contains(node):
            return self.lower_vector_op(node)
        -1

    // `node`'s own value, without the splat or conversion recorded on it.
    mut fn lower_vector_raw(node: i32) -> i32:
        let saved = self.vector_raw_node
        self.vector_raw_node = node
        let op = self.lower_expr(node)
        self.vector_raw_node = saved
        op

    mut fn lower_vector_splat_node(node: i32) -> i32:
        let vec_ty: i32 = self.sema.vector_splats.get(node).unwrap()
        let scalar = self.lower_vector_raw(node)
        self.lower_vector_splat(scalar, vec_ty, self.ast.get_start(node))

    mut fn lower_vector_conversion_node(node: i32) -> i32:
        let target: i32 = self.sema.vector_conversions.get(node).unwrap()
        let op = self.lower_vector_raw(node)
        let src_ty = self.operand_type(op)
        self.lower_value_cast(op, src_ty, target, self.ast.get_start(node))

    // `scalar` as a lane of `vec_ty`: converted to the lane type when Sema
    // accepted a lossless widening of it (§4.2.6).
    mut fn lower_vector_lane_operand(scalar: i32, lane: i32, span: i32) -> i32:
        let ty = self.operand_type(scalar)
        if ty == lane or self.sema.types_identical(ty, lane):
            return scalar
        self.lower_value_cast(scalar, ty, lane, span)

    // Every lane of a `vec_ty` holding `scalar`.
    mut fn lower_vector_splat(scalar: i32, vec_ty: i32, span: i32) -> i32:
        let lane = self.sema.vector_lane_type(vec_ty)
        let lane_op = self.lower_vector_lane_operand(scalar, lane, span)
        let lane_place = self.materialize_operand(lane_op, lane, span)
        let lanes: Vec[i32] = Vec.new()
        for _ in 0..self.sema.vector_lane_count(vec_ty):
            lanes.push(self.body.new_operand(OperandKind.OK_COPY, lane_place))
        self.lower_vector_aggregate(lanes, vec_ty, span)

    mut fn lower_vector_aggregate(lanes: &Vec[i32], vec_ty: i32, span: i32) -> i32:
        // A lane has no name.
        let names: Vec[i32] = Vec.new()
        for _ in 0..lanes.len():
            names.push(0)
        let fid = self.body.new_agg_fields(lanes, names)
        let rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, fid, 0)
        let temp = self.new_temp(vec_ty)
        let place = self.place_for_local(temp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, span)
        self.body.new_operand(OperandKind.OK_COPY, place)

    // The place of lane `lane` of the vector in `base_place`.
    mut fn vector_lane_place(base_place: i32, lane: i32, lane_ty: i32, span: i32) -> i32:
        let idx_local = self.new_temp(self.sema.ty_i32 as i32)
        let idx_place = self.place_for_local(idx_local)
        let idx_op = self.int_const_operand(lane as i64, self.sema.ty_i32 as i32)
        self.assign_operand_to_place(idx_place, idx_op, span)
        self.body.new_index_place(base_place, idx_local, lane_ty)

    mut fn lower_vector_intrinsic(kind: MirIntrinsic, args: &Vec[i32], ret_ty: i32, node: i32) -> i32:
        let args_id = self.body.new_call_args(args)
        self.body.set_call_intrinsic(args_id, kind)
        self.body.set_call_ast_node(args_id, node)
        let result_local = self.new_temp(ret_ty)
        let result_place = self.place_for_local(result_local)
        let callee = self.unit_operand()
        let next_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, callee, args_id, result_place, next_bb)
        self.switch_to(next_bb)
        self.body.new_operand(OperandKind.OK_COPY, result_place)

    // The receiver of `v.bits()`, `m.all()`, `v.reduce_add()`: the call's
    // callee is the field access and its base the receiver.
    mut fn lower_vector_receiver(call_node: i32) -> i32:
        self.lower_expr(self.ast.get_data0(self.ast.get_data0(call_node)))

    mut fn lower_vector_op(node: i32) -> i32:
        let op: i32 = self.sema.vector_ops.get(node).unwrap()
        let ty = self.expr_type(node)
        let span = self.ast.get_start(node)
        if op == VectorOp.SWIZZLE as i32:
            return self.lower_vector_swizzle(node, ty, span)
        let extra_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        if op == VectorOp.CONSTRUCT as i32:
            let lane = self.sema.vector_lane_type(ty)
            let lanes: Vec[i32] = Vec.new()
            for ai in 0..arg_count:
                let arg = self.lower_expr(self.ast.get_extra(extra_start + ai))
                lanes.push(self.lower_vector_lane_operand(arg, lane, span))
            return self.lower_vector_aggregate(lanes, ty, span)
        if op == VectorOp.SPLAT as i32:
            let splat_arg = self.lower_expr(self.ast.get_extra(extra_start))
            return self.lower_vector_splat(splat_arg, ty, span)
        let args: Vec[i32] = Vec.new()
        var kind = MirIntrinsic.NONE
        if op == VectorOp.FROM_BITS as i32:
            args.push(self.lower_expr(self.ast.get_extra(extra_start)))
            kind = MirIntrinsic.SIMD_BITCAST
        else if op == VectorOp.SELECT as i32:
            for ai in 0..arg_count:
                args.push(self.lower_expr(self.ast.get_extra(extra_start + ai)))
            kind = MirIntrinsic.SIMD_SELECT
        else:
            args.push(self.lower_vector_receiver(node))
            if op == VectorOp.BITS as i32: kind = MirIntrinsic.SIMD_BITCAST
            else if op == VectorOp.ALL as i32: kind = MirIntrinsic.SIMD_ALL
            else if op == VectorOp.ANY as i32: kind = MirIntrinsic.SIMD_ANY
            else if op == VectorOp.REDUCE_ADD as i32: kind = MirIntrinsic.SIMD_REDUCE_ADD
            else if op == VectorOp.REDUCE_MUL as i32: kind = MirIntrinsic.SIMD_REDUCE_MUL
            else if op == VectorOp.REDUCE_MIN as i32: kind = MirIntrinsic.SIMD_REDUCE_MIN
            else if op == VectorOp.REDUCE_MAX as i32: kind = MirIntrinsic.SIMD_REDUCE_MAX
            else if op == VectorOp.REDUCE_AND as i32: kind = MirIntrinsic.SIMD_REDUCE_AND
            else if op == VectorOp.REDUCE_OR as i32: kind = MirIntrinsic.SIMD_REDUCE_OR
            else if op == VectorOp.REDUCE_XOR as i32: kind = MirIntrinsic.SIMD_REDUCE_XOR
        if kind == MirIntrinsic.NONE:
            // Post-Sema invalid MIR is a compiler bug (D65): never guess.
            self.mark_unsupported()
            return self.unit_operand()
        self.lower_vector_intrinsic(kind, args, ty, node)

    // `v.x` reads lane 0; `v.wzyx` builds the vector of the named lanes.
    mut fn lower_vector_swizzle(node: i32, ty: i32, span: i32) -> i32:
        let lanes_text = self.sema.vector_swizzles.get(node).unwrap().clone()
        let base = self.lower_expr(self.ast.get_data0(node))
        let base_ty = self.operand_type(base)
        let base_place = self.materialize_operand(base, base_ty, span)
        let lane_ty = self.sema.vector_lane_type(base_ty)
        let lanes: Vec[i32] = Vec.new()
        for ci in 0..lanes_text.len() as i32:
            let lane = (lanes_text[ci] - '0') as i32
            let lane_place = self.vector_lane_place(base_place, lane, lane_ty, span)
            lanes.push(self.body.new_operand(OperandKind.OK_COPY, lane_place))
        if lanes.len() == 1:
            return lanes[0]
        self.lower_vector_aggregate(lanes, ty, span)
