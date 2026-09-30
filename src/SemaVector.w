// SemaVector — §4.3d SIMD vector types (D78, #1874): the facts Sema owns
// about `Vector[N, T]` and `Mask[N, W]`.
//
// `Vector[N, T]` is TypeKind.TY_VECTOR (d0 = lane type, d1 = N); `Mask[N, W]`
// is TypeKind.TY_MASK (d0 = W, d1 = N). The one-token aliases (`f32x4`,
// `m32x4`, …) are registered names for those same types, for the native
// widths (N × width ∈ 128, 256, 512 bits); a diagnostic prints the alias
// where one exists, as c_import does (§16.1).

use Sema
use SemaTypes
use SemaCheck
use SemaDiag
use Ast

// The lane widths an alias exists for, and the native vector widths.
fn vector_native_total_bits(total: i32) -> bool: total == 128 or total == 256 or total == 512

impl Sema:
    // Called once while the primitive names are registered: every alias
    // names its Vector or Mask type.
    mut fn register_vector_aliases():
        let lanes: Vec[i32] = Vec.new()
        lanes.push(self.ty_i8 as i32)
        lanes.push(self.ty_i16 as i32)
        lanes.push(self.ty_i32 as i32)
        lanes.push(self.ty_i64 as i32)
        lanes.push(self.ty_u8 as i32)
        lanes.push(self.ty_u16 as i32)
        lanes.push(self.ty_u32 as i32)
        lanes.push(self.ty_u64 as i32)
        lanes.push(self.ty_i128 as i32)
        lanes.push(self.ty_u128 as i32)
        lanes.push(self.ty_f32 as i32)
        lanes.push(self.ty_f64 as i32)
        for li in 0..lanes.len() as i32:
            let lane = lanes[li]
            let bits = self.get_type_d0(lane as TypeId)
            for total in [128, 256, 512]:
                let n = total / bits
                let tid = self.vector_type(lane, n)
                self.register_prim(self.type_name(lane) ++ f"x{n}", tid)
        for w in [8, 16, 32, 64, 128]:
            for total in [128, 256, 512]:
                let n = total / w
                self.register_prim(f"m{w}x{n}", self.mask_type(w, n))

    fn vector_type(lane: i32, n: i32) -> i32: self.ensure_exact_type(TypeKind.TY_VECTOR, lane, n, 0) as i32

    fn mask_type(w: i32, n: i32) -> i32: self.ensure_exact_type(TypeKind.TY_MASK, w, n, 0) as i32

    fn is_vector_type(tid: i32) -> bool:
        tid > 0 and self.get_type_kind(self.resolve_alias(tid as TypeId)) == TypeKind.TY_VECTOR

    fn is_mask_type(tid: i32) -> bool:
        tid > 0 and self.get_type_kind(self.resolve_alias(tid as TypeId)) == TypeKind.TY_MASK

    fn is_vector_or_mask_type(tid: i32) -> bool: self.is_vector_type(tid) or self.is_mask_type(tid)

    // A Vector's lane type; 0 for anything else.
    fn vector_lane_type(tid: i32) -> i32:
        if not self.is_vector_type(tid): return 0
        self.get_type_d0(self.resolve_alias(tid as TypeId))

    // What one lane holds: a Vector's lane type, a Mask's `bool` (§4.3d
    // Masks: constructed and indexed as bools); 0 for anything else.
    fn vector_element_type(tid: i32) -> i32:
        if self.is_mask_type(tid): return self.ty_bool as i32
        self.vector_lane_type(tid)

    // A Vector's or Mask's lane count; 0 for anything else.
    fn vector_lane_count(tid: i32) -> i32:
        if not self.is_vector_or_mask_type(tid): return 0
        self.get_type_d1(self.resolve_alias(tid as TypeId))

    // A Mask's lane width in bits; 0 for anything else.
    fn mask_lane_bits(tid: i32) -> i32:
        if not self.is_mask_type(tid): return 0
        self.get_type_d0(self.resolve_alias(tid as TypeId))

    // The width in bits of a lane type (8..64).
    fn vector_lane_bits(lane: i32) -> i32: self.get_type_d0(self.resolve_alias(lane as TypeId))

    fn vector_lane_is_float(tid: i32) -> bool:
        let lane = self.vector_lane_type(tid)
        lane != 0 and self.get_type_kind(self.resolve_alias(lane as TypeId)) == TypeKind.TY_FLOAT

    // §4.3d: what a lane-wise comparison of `tid` yields,
    // Mask[N, width(T)].
    fn vector_compare_mask_type(tid: i32) -> i32:
        self.mask_type(self.vector_lane_bits(self.vector_lane_type(tid)), self.vector_lane_count(tid))

    // §4.3d: `.bits()` — the unsigned integer vector of the same lane width.
    fn vector_bits_type(tid: i32) -> i32:
        let bits = self.vector_lane_bits(self.vector_lane_type(tid))
        let lane = if bits == 8: self.ty_u8 else if bits == 16: self.ty_u16 else if bits == 32: self.ty_u32 else if bits == 64: self.ty_u64 else: self.ty_u128
        self.vector_type(lane as i32, self.vector_lane_count(tid))

    // §4.3d: T is a primitive integer (§4.1: i8…i128, u8…u128) or floating
    // type.
    fn vector_lane_type_is_valid(lane: i32) -> bool:
        if lane <= 0: return false
        let resolved = self.resolve_alias(lane as TypeId)
        let kind = self.get_type_kind(resolved)
        let bits = self.get_type_d0(resolved)
        if kind == TypeKind.TY_FLOAT: return bits == 32 or bits == 64
        if kind == TypeKind.TY_INT: return bits == 8 or bits == 16 or bits == 32 or bits == 64 or bits == 128
        false

    // §4.3d: the compile-time integer a generic lane count `N` is bound to
    // (`fn dot[N](a: Vector[N, f32])`), as a generic substitution.
    fn const_int_type(value: i32) -> i32: self.ensure_exact_type(TypeKind.TY_CONST_INT, value, 0, 0) as i32

    fn const_int_value(tid: i32) -> i32:
        if tid <= 0 or self.get_type_kind(self.resolve_alias(tid as TypeId)) != TypeKind.TY_CONST_INT: return -1
        self.get_type_d0(self.resolve_alias(tid as TypeId))

    // The value of a lane-count node: an integer literal, or a generic
    // parameter bound to one (`subst` resolves a bare name; -1 if neither).
    fn vector_count_node_value(node: i32, subst: i32) -> i64:
        let value = self.int_literal_i64_value(node)
        if value.ok != 0: return value.value
        let kind = self.ast.kind(node)
        if subst != 0 and (kind == NodeKind.NK_TYPE_NAMED or kind == NodeKind.NK_IDENT):
            let bound = self.const_int_value(subst)
            if bound >= 0: return bound as i64
        -1

    // The generic substitution a bare lane-count name has in scope, or 0.
    fn vector_count_subst(node: i32) -> i32:
        let kind = self.ast.kind(node)
        if kind != NodeKind.NK_TYPE_NAMED and kind != NodeKind.NK_IDENT: return 0
        self.lookup_generic_subst(self.ast.get_data0(node))

    // The name a diagnostic prints: the alias where one exists.
    fn vector_type_name(tid: i32) -> str:
        let resolved = self.resolve_alias(tid as TypeId)
        let n = self.get_type_d1(resolved)
        if self.get_type_kind(resolved) == TypeKind.TY_MASK:
            let w = self.get_type_d0(resolved)
            if vector_native_total_bits(w * n): return f"m{w}x{n}"
            return f"Mask[{n}, {w}]"
        let lane = self.get_type_d0(resolved)
        let lane_name = self.type_name(lane)
        let pointer_width = self.get_type_d2(self.resolve_alias(lane as TypeId)) != 0
        if not pointer_width and vector_native_total_bits(self.vector_lane_bits(lane) * n):
            return lane_name ++ f"x{n}"
        f"Vector[{n}, {lane_name}]"

    fn is_vector_symbol(sym: i32) -> bool: self.lookup_named_type_visible(sym) == 0 and self.pool_resolve_symbol(sym) == "Vector"

    fn is_mask_symbol(sym: i32) -> bool: self.lookup_named_type_visible(sym) == 0 and self.pool_resolve_symbol(sym) == "Mask"

    // The lane count argument of `Vector[N, T]` / `Mask[N, W]`: a
    // compile-time integer constant ≥ 1, or -1 after a diagnostic.
    mut fn vector_count_arg(node: i32, what: &str) -> i32:
        self.vector_count_arg_with(node, what, self.vector_count_subst(node))

    mut fn vector_count_arg_with(node: i32, what: &str, subst: i32) -> i32:
        let value = self.vector_count_node_value(node, subst)
        if value == -1:
            self.emit_error(f"{what}'s lane count must be a compile-time integer constant or a generic parameter the arguments bind (§4.3d)", node)
            return -1
        if value < 1:
            self.emit_error("a vector has at least one lane (§4.3d: N ≥ 1)", node)
            return -1
        if value > 2147483647:
            self.emit_error(f"{what}'s lane count is too large", node)
            return -1
        value as i32

    // `Vector[N, T]` from its two argument nodes; `lane` is the resolved T.
    mut fn vector_type_from_args(count_node: i32, lane: i32, lane_node: i32, count_subst: i32) -> i32:
        let n = self.vector_count_arg_with(count_node, "Vector", count_subst)
        if n < 0 or lane == 0: return 0
        if not self.vector_lane_type_is_valid(lane):
            self.emit_error(f"a vector lane is a primitive integer or floating type of 8, 16, 32 or 64 bits, not `{self.type_name(lane)}` (§4.3d)", lane_node)
            return 0
        self.vector_type(lane, n)

    // `Mask[N, W]` from its two argument nodes.
    mut fn mask_type_from_args(count_node: i32, width_node: i32) -> i32:
        let n = self.vector_count_arg(count_node, "Mask")
        if n < 0: return 0
        let w = self.int_literal_i64_value(width_node)
        if w.ok == 0 or (w.value != 8 and w.value != 16 and w.value != 32 and w.value != 64 and w.value != 128):
            self.emit_error("a mask's lane width is 8, 16, 32, 64 or 128 bits (§4.3d)", width_node)
            return 0
        self.mask_type(w.value as i32, n)

    // A resolved `Vector[...]`/`Mask[...]` type expression with argument
    // nodes `a0` and `a1`; `resolve_lane` resolves a type argument.
    mut fn resolve_vector_generic(base_sym: i32, arg_count: i32, a0: i32, a1: i32, node: i32) -> i32:
        let name = self.pool_resolve_symbol(base_sym).clone()
        if arg_count != 2:
            self.emit_error(f"{name} takes two arguments: `{name}[N, " ++ (if name == "Vector": "T" else: "W") ++ "]` (§4.3d)", node)
            return 0
        if name == "Mask": return self.mask_type_from_args(a0, a1)
        let lane = self.resolve_type_level_arg_expr(a1)
        self.vector_type_from_args(a0, lane, a1, self.vector_count_subst(a0))

    // The frozen twin: every Vector/Mask type a MIR-era consumer names was
    // registered while checking.
    fn resolve_vector_generic_frozen(base_sym: i32, a0: i32, a1: i32) -> i32:
        let n = self.vector_count_node_value(a0, self.vector_count_subst(a0))
        if n < 1: return 0
        if self.pool_resolve_symbol(base_sym) == "Mask":
            let w = self.int_literal_i64_value(a1)
            if w.ok == 0: return 0
            return self.find_exact_type(TypeKind.TY_MASK, w.value as i32, n as i32, 0) as i32
        let lane = self.resolve_type_level_arg_expr_frozen(a1)
        self.find_exact_type(TypeKind.TY_VECTOR, lane, n as i32, 0) as i32

    // ── Expressions ─────────────────────────────────────────────────

    // The Vector or Mask type an expression names when it is used as a
    // constructor (`f32x4`, `Vector[4, f32]`), or 0. A binding of the same
    // name is a value, not the type.
    mut fn vector_type_named_by(node: i32) -> i32:
        if node <= 0: return 0
        let kind = self.ast.kind(node)
        if kind == NodeKind.NK_IDENT or kind == NodeKind.NK_TYPE_NAMED:
            let sym = self.ast.get_data0(node)
            if self.scope_lookup(sym) >= 0: return 0
            let tid = self.lookup_named_type_visible(sym)
            if self.is_vector_or_mask_type(tid): return tid
            return 0
        if kind == NodeKind.NK_INDEX:
            let base = self.ast.get_data0(node)
            if self.ast.kind(base) != NodeKind.NK_IDENT: return 0
            let base_sym = self.ast.get_data0(base)
            if not self.is_vector_symbol(base_sym) and not self.is_mask_symbol(base_sym): return 0
            return self.resolve_type_level_arg_expr(node)
        if kind == NodeKind.NK_TYPE_GENERIC:
            let gsym = self.ast.get_data0(node)
            if not self.is_vector_symbol(gsym) and not self.is_mask_symbol(gsym): return 0
            return self.resolve_generic_type(node)
        0

    // A call Sema lowers as a vector or mask construction, `splat` or
    // `from_bits`. -1 when `callee` is none of them.
    mut fn check_vector_call(node: i32, callee: i32, extra_start: i32, arg_count: i32) -> i32:
        let ck = self.ast.kind(callee)
        if ck == NodeKind.NK_IDENT or ck == NodeKind.NK_INDEX or ck == NodeKind.NK_TYPE_GENERIC:
            let ctor_ty = self.vector_type_named_by(callee)
            if ctor_ty == 0: return -1
            return self.check_vector_construct(node, ctor_ty, extra_start, arg_count)
        if ck == NodeKind.NK_FIELD_ACCESS:
            let base = self.ast.get_data0(callee)
            let bk = self.ast.kind(base)
            if bk != NodeKind.NK_IDENT and bk != NodeKind.NK_INDEX: return -1
            let base_ty = self.vector_type_named_by(base)
            if base_ty == 0: return -1
            let method = self.pool_resolve_symbol(self.ast.get_data1(callee)).clone()
            let type_text = self.type_name(base_ty)
            if method == "splat":
                if arg_count != 1:
                    self.emit_error(f"{type_text}.splat takes one value", node)
                    return 0
                let _ = self.check_expr_with_owned_demand(self.ast.get_extra(extra_start), self.vector_element_type(base_ty) as TypeId)
                return self.record_vector_op(node, VectorOp.SPLAT, base_ty)
            if not self.is_vector_type(base_ty):
                if method == "from_bits":
                    self.emit_error(f"`{type_text}.from_bits` is refused: a true lane from bits could be `1` or `-1`, two meanings (§4.3d); build the mask from a comparison, `{type_text}(...)` or `{type_text}.splat(b)`", callee)
                    return 0
                self.emit_error(f"`{type_text}` has no associated function `{method}`; a mask is built with `{type_text}(...)` or `{type_text}.splat(b)` (§4.3d)", callee)
                return 0
            if method == "from_bits":
                if arg_count != 1:
                    self.emit_error(f"{type_text}.from_bits takes one value", node)
                    return 0
                let arg = self.ast.get_extra(extra_start)
                let bits_ty = self.vector_bits_type(base_ty)
                let got0 = self.check_expr_with_expected(arg, bits_ty as TypeId) as i32
                if got0 == 0: return 0
                let got = self.vector_value_type(arg, got0)
                if not self.types_identical(got, bits_ty):
                    self.emit_error(f"{type_text}.from_bits takes the `{self.type_name(bits_ty)}` that `.bits()` gives, not `{self.type_name(got)}` (§4.3d)", arg)
                    return 0
                return self.record_vector_op(node, VectorOp.FROM_BITS, base_ty)
            self.emit_error(f"`{type_text}` has no associated function `{method}`; a vector is built with `{type_text}(...)`, `{type_text}.splat(s)` or `{type_text}.from_bits(u)` (§4.3d)", callee)
            return 0
        -1

    mut fn record_vector_op(node: i32, op: VectorOp, result: i32) -> i32:
        self.vector_ops.insert(node, op as i32)
        self.typed_expr_types.insert(node, result)
        result

    // A vector-or-mask value reached through Copy views (`arr[i]` is
    // `&f32x4`) is the value the view observes; `node` materializes it.
    mut fn vector_value_type(node: i32, ty: i32) -> i32:
        if self.is_vector_or_mask_type(ty): return ty
        let pointee = self.shared_copy_pointee(ty)
        if pointee != 0 and self.is_vector_or_mask_type(pointee):
            let _ = self.record_contextual_copy_adjustment(node, pointee, ty)
            return pointee
        ty

    mut fn check_vector_construct(node: i32, vec_ty: i32, extra_start: i32, arg_count: i32) -> i32:
        let type_text = self.type_name(vec_ty)
        let n = self.vector_lane_count(vec_ty)
        if arg_count != n:
            for ai in 0..arg_count:
                let _ = self.check_expr_value_context(self.ast.get_extra(extra_start + ai))
            self.emit_error(f"{type_text} takes exactly {n} lane values, not {arg_count} (§4.3d); `{type_text}.splat(s)` puts one value in every lane", node)
            return 0
        let lane = self.vector_element_type(vec_ty)
        for ai in 0..arg_count:
            let _ = self.check_expr_with_owned_demand(self.ast.get_extra(extra_start + ai), lane as TypeId)
        self.record_vector_op(node, VectorOp.CONSTRUCT, vec_ty)

    // `m.select(a, b)` (D80): `a`'s lane where `m` is true, `b`'s where it
    // is false; `a` and `b` share one vector type and `m` is the mask its
    // comparison yields.
    mut fn check_vector_select(node: i32, m_ty: i32, extra_start: i32, arg_count: i32) -> i32:
        if arg_count != 2:
            self.emit_error("select takes two operands: `m.select(a, b)` (§4.3d)", node)
            return 0
        let a_node = self.ast.get_extra(extra_start)
        let b_node = self.ast.get_extra(extra_start + 1)
        // D80 amendment (v7.16): a scalar `a` or `b` broadcasts as an
        // operator's scalar operand does — the vector type comes from the
        // other operand or from the context; two scalars with no vector
        // context have no one meaning and are refused.
        var vec_ty = if self.has_expected_type != 0 and self.is_vector_type(self.expected_expr_type as i32): self.expected_expr_type as i32 else: 0
        var a_ty = 0
        var b_ty = 0
        if vec_ty == 0 and not self.expr_is_untyped_literal_arith(a_node):
            let a_exact = self.check_expr_value_context(a_node) as i32
            a_ty = self.vector_value_type(a_node, a_exact)
            if a_ty == 0: return 0
            if self.is_vector_type(a_ty): vec_ty = a_ty
        if vec_ty == 0 and not self.expr_is_untyped_literal_arith(b_node):
            let b_exact = self.check_expr_value_context(b_node) as i32
            b_ty = self.vector_value_type(b_node, b_exact)
            if b_ty == 0: return 0
            if self.is_vector_type(b_ty): vec_ty = b_ty
        if vec_ty == 0:
            self.emit_error("`m.select(a, b)` needs a vector: a scalar operand broadcasts only beside a vector operand or where the context gives the vector type (§4.3d)", node)
            return 0
        if a_ty == 0:
            let a_exact2 = self.check_expr_with_expected(a_node, vec_ty as TypeId) as i32
            a_ty = self.vector_value_type(a_node, a_exact2)
        if b_ty == 0:
            let b_exact2 = self.check_expr_with_expected(b_node, vec_ty as TypeId) as i32
            b_ty = self.vector_value_type(b_node, b_exact2)
        if a_ty == 0 or b_ty == 0: return 0
        if not self.select_operand_ok(a_node, a_ty, vec_ty) or not self.select_operand_ok(b_node, b_ty, vec_ty):
            return 0
        let want_mask = self.vector_compare_mask_type(vec_ty)
        if not self.types_identical(m_ty, want_mask):
            self.emit_error(f"select over `{self.type_name(vec_ty)}` takes a `{self.type_name(want_mask)}` mask, not `{self.type_name(m_ty)}` (§4.3d)", node)
            return 0
        self.record_vector_op(node, VectorOp.SELECT, vec_ty)

    // One operand of `m.select(a, b)` against the vector type: the vector
    // itself, or a scalar that broadcasts (a literal already splatted).
    mut fn select_operand_ok(node: i32, ty: i32, vec_ty: i32) -> bool:
        if self.is_vector_type(ty):
            if self.types_identical(ty, vec_ty): return true
            self.emit_error(f"select picks between two vectors of one type, not `{self.type_name(ty)}` and `{self.type_name(vec_ty)}` (§4.3d)", node)
            return false
        if not self.vector_scalar_operand_ok(node, ty, vec_ty, false): return false
        self.vector_splats.insert(node, vec_ty)
        true

    // A method on a vector or mask value: `.all()`, `.any()`, the
    // reductions, `.bits()`. -1 when `field` is none of them.
    mut fn check_vector_method(node: i32, recv_node: i32, recv_ty0: i32, field: i32, arg_count: i32) -> i32:
        let recv_ty = self.vector_value_type(recv_node, recv_ty0)
        if not self.is_vector_or_mask_type(recv_ty): return -1
        let name = self.pool_resolve_symbol(field).clone()
        let type_text = self.type_name(recv_ty)
        var op = 0
        if self.is_mask_type(recv_ty):
            if name == "select": return self.check_vector_select(node, recv_ty, self.ast.get_data1(node), arg_count)
            if name == "all": op = VectorOp.ALL as i32
            else if name == "any": op = VectorOp.ANY as i32
            else if name == "bits":
                self.emit_error(f"`{type_text}.bits()` is refused: a true lane read as bits is `1` or `-1`, two meanings (§4.3d); read lanes with `m[i]` or pick with `m.select(a, b)`", node)
                return 0
            else: return -1
        else:
            if name == "reduce_add": op = VectorOp.REDUCE_ADD as i32
            else if name == "reduce_mul": op = VectorOp.REDUCE_MUL as i32
            else if name == "reduce_min": op = VectorOp.REDUCE_MIN as i32
            else if name == "reduce_max": op = VectorOp.REDUCE_MAX as i32
            else if name == "reduce_and": op = VectorOp.REDUCE_AND as i32
            else if name == "reduce_or": op = VectorOp.REDUCE_OR as i32
            else if name == "reduce_xor": op = VectorOp.REDUCE_XOR as i32
            else if name == "bits": op = VectorOp.BITS as i32
            else: return -1
        if arg_count != 0:
            self.emit_error(f"{type_text}.{name}() takes no arguments", node)
            return 0
        var result = self.vector_lane_type(recv_ty)
        if op == VectorOp.ALL as i32 or op == VectorOp.ANY as i32:
            result = self.ty_bool as i32
        else if op == VectorOp.BITS as i32:
            result = self.vector_bits_type(recv_ty)
        else if (op == VectorOp.REDUCE_AND as i32 or op == VectorOp.REDUCE_OR as i32 or op == VectorOp.REDUCE_XOR as i32) and self.vector_lane_is_float(recv_ty):
            self.emit_error(f"{name} reduces integer lanes; `{type_text}` has float lanes (§4.3d)", node)
            return 0
        self.vector_ops.insert(node, op)
        self.typed_expr_types.insert(node, result)
        result

    // `v.x`, `v.xy`, `v.wzyx`: clang's ext_vector_type components and
    // swizzles, for N ≤ 4. -1 when `field` is no component spelling.
    mut fn check_vector_swizzle(node: i32, recv_node: i32, recv_ty0: i32, field: i32) -> i32:
        let recv_ty = self.vector_value_type(recv_node, recv_ty0)
        let name = self.pool_resolve_symbol(field).clone()
        if name.len() == 0: return -1
        if self.is_mask_type(recv_ty):
            var components = true
            for mi in 0..name.len() as i32:
                let mc = name[mi]
                if mc != 'x' and mc != 'y' and mc != 'z' and mc != 'w': components = false
            if components:
                self.emit_error(f"`.{name}` on the mask `{self.type_name(recv_ty)}` is refused: a mask's lanes are `m[i]` (§4.3d)", node)
                return 0
            return -1
        if not self.is_vector_type(recv_ty): return -1
        var lanes = ""
        for ci in 0..name.len() as i32:
            let c = name[ci]
            let lane = if c == 'x': 0 else if c == 'y': 1 else if c == 'z': 2 else if c == 'w': 3 else: -1
            if lane < 0: return -1
            lanes = lanes ++ f"{lane}"
        let n = self.vector_lane_count(recv_ty)
        let type_text = self.type_name(recv_ty)
        if n > 4:
            self.emit_error(f"`{type_text}` has {n} lanes; the components .x .y .z .w name the lanes of a vector of at most 4 (§4.3d); read lane i with `v[i]`", node)
            return 0
        for ci in 0..name.len() as i32:
            let lane = (lanes[ci] - '0') as i32
            if lane >= n:
                let comp = name.slice(ci as i64, ci as i64 + 1)
                self.emit_error(f"swizzle component `{comp}` names lane {lane} of a {n}-lane vector (§4.3d)", node)
                return 0
        self.vector_swizzles.insert(node, lanes)
        let lane_ty = self.vector_lane_type(recv_ty)
        let out = if name.len() == 1: lane_ty else: self.vector_type(lane_ty, name.len() as i32)
        self.record_vector_op(node, VectorOp.SWIZZLE, out)

    // How many lanes the swizzle at `node` names (0 when none).
    fn vector_swizzle_width(node: i32) -> i32:
        if not self.vector_swizzles.contains(node): return 0
        self.vector_swizzles.get(node).unwrap().len() as i32

    // `v[i]`: lane i, a value of the lane type. A constant index is checked
    // here (§4.3a's array rule); a runtime one panics out of range.
    mut fn check_vector_index(node: i32, vec_ty: i32, index: i32) -> i32:
        self.check_runtime_index_operand(index)
        let n = self.vector_lane_count(vec_ty)
        let k = self.int_literal_i64_value(index)
        if k.ok != 0 and (k.value < 0 or k.value >= n as i64):
            self.emit_error(f"lane index {k.value} is out of range for {self.type_name(vec_ty)} ({n} lanes, §4.3d)", index)
            return 0
        let lane = self.vector_element_type(vec_ty)
        // `m[i]` reads a mask lane as a bool (D80); its storage is W bits, so
        // it is a value, not a place.
        if self.is_mask_type(vec_ty):
            return self.record_vector_op(node, VectorOp.MASK_LANE, lane)
        self.typed_expr_types.insert(node, lane)
        lane

    // A lane-wise binary operator (§4.3d). -1 when neither operand is a
    // vector or a mask.
    mut fn check_vector_binary(node: i32, op: i32, lhs_node: i32, rhs_node: i32, lhs0: i32, rhs0: i32) -> i32:
        let lhs = self.vector_value_type(lhs_node, lhs0)
        let rhs = self.vector_value_type(rhs_node, rhs0)
        let lv = self.is_vector_type(lhs)
        let rv = self.is_vector_type(rhs)
        if self.is_mask_type(lhs) or self.is_mask_type(rhs):
            return self.check_mask_binary(node, op, lhs_node, rhs_node, lhs, rhs)
        if not lv and not rv: return -1
        var vec_ty = if lv: lhs else: rhs
        if lv and rv and not self.types_identical(lhs, rhs):
            // §4.2 per lane: lanes of one kind and signedness widen
            // losslessly to the wider (§4.2.4 rule 2, §4.2.6).
            let common = self.vector_common_type(lhs, rhs)
            if common == 0:
                if self.vector_lane_count(lhs) == self.vector_lane_count(rhs) and not self.vector_lane_is_float(lhs) and not self.vector_lane_is_float(rhs):
                    self.emit_error(f"lane-wise operator needs vectors of one lane signedness, not `{self.type_name(lhs)}` and `{self.type_name(rhs)}`; convert one with `as` (§4.2.4, §4.3d)", node)
                else:
                    self.emit_error(f"lane-wise operator needs vectors of the same shape, not `{self.type_name(lhs)}` and `{self.type_name(rhs)}` (§4.3d); convert one with `as`", node)
                return 0
            if not self.types_identical(lhs, common):
                self.vector_conversions.insert(lhs_node, common)
            if not self.types_identical(rhs, common):
                self.vector_conversions.insert(rhs_node, common)
            vec_ty = common
        let type_text = self.type_name(vec_ty)
        let is_cmp = op == BinaryOp.OP_EQ or op == BinaryOp.OP_NEQ or op == BinaryOp.OP_LT or op == BinaryOp.OP_GT or op == BinaryOp.OP_LTE or op == BinaryOp.OP_GTE
        let is_shift = op == BinaryOp.OP_SHL or op == BinaryOp.OP_SHR
        let is_int_only = is_shift or op == BinaryOp.OP_BIT_AND or op == BinaryOp.OP_BIT_OR or op == BinaryOp.OP_BIT_XOR or
            op == BinaryOp.OP_ADD_WRAP or op == BinaryOp.OP_SUB_WRAP or op == BinaryOp.OP_MUL_WRAP or op == BinaryOp.OP_ADD_SAT or op == BinaryOp.OP_SUB_SAT or op == BinaryOp.OP_MUL_SAT
        let is_arith = op == BinaryOp.OP_ADD or op == BinaryOp.OP_SUB or op == BinaryOp.OP_MUL or op == BinaryOp.OP_DIV or op == BinaryOp.OP_MOD
        if not is_cmp and not is_int_only and not is_arith:
            self.emit_error(f"operator '{sema_operator_symbol_text(op)}' is not lane-wise on `{type_text}` (§4.3d)", node)
            return 0
        if is_int_only and self.vector_lane_is_float(vec_ty):
            self.emit_error(f"operator '{sema_operator_symbol_text(op)}' needs integer lanes; `{type_text}` has float lanes (§4.3d)", node)
            return 0
        if not (lv and rv):
            // §4.3d: a scalar operand beside a vector broadcasts to every lane.
            // A scalar shift amount is any integer; a scalar shifted by a
            // vector (`2 << v`) is a lane value like any other operand.
            let scalar_node = if lv: rhs_node else: lhs_node
            let scalar_ty = if lv: rhs else: lhs
            if not self.vector_scalar_operand_ok(scalar_node, scalar_ty, vec_ty, is_shift and lv):
                return 0
            self.vector_splats.insert(scalar_node, vec_ty)
        let result = if is_cmp: self.vector_compare_mask_type(vec_ty) else: vec_ty
        self.typed_expr_types.insert(node, result)
        result

    // `&`, `|`, `^` on masks of one shape, a `bool` operand broadcasting
    // (D80). `and`/`or` short-circuit, which lanes cannot; nothing else is
    // defined on a mask.
    mut fn check_mask_binary(node: i32, op: i32, lhs_node: i32, rhs_node: i32, lhs: i32, rhs: i32) -> i32:
        let mask_ty = if self.is_mask_type(lhs): lhs else: rhs
        let type_text = self.type_name(mask_ty)
        if op == BinaryOp.OP_AND or op == BinaryOp.OP_OR:
            self.emit_error(f"`{sema_operator_symbol_text(op)}` short-circuits, and the lanes of `{type_text}` cannot; combine masks with `&` or `|` (§4.3d)", node)
            return 0
        if op == BinaryOp.OP_EQ or op == BinaryOp.OP_NEQ:
            self.emit_error(f"`{sema_operator_symbol_text(op)}` on masks is refused: it could mean one `bool` for the whole mask or a lane-wise mask (§4.3d); spell `(m ^ n).any()` or `not (m ^ n)`", node)
            return 0
        if op != BinaryOp.OP_BIT_AND and op != BinaryOp.OP_BIT_OR and op != BinaryOp.OP_BIT_XOR:
            self.emit_error(f"operator '{sema_operator_symbol_text(op)}' is not defined on a mask; masks combine with `&`, `|`, `^` and `not`, and `.select`, `.all()` and `.any()` read one (§4.3d)", node)
            return 0
        if self.is_mask_type(lhs) and self.is_mask_type(rhs):
            if not self.types_identical(lhs, rhs):
                self.emit_error(f"masks of different widths do not combine: `{self.type_name(lhs)}` and `{self.type_name(rhs)}`; convert one with `as` (§4.3d)", node)
                return 0
        else:
            let other_node = if self.is_mask_type(lhs): rhs_node else: lhs_node
            let other_ty0 = if self.is_mask_type(lhs): rhs else: lhs
            let pointee = self.shared_copy_pointee(other_ty0)
            let other_ty = if pointee == self.ty_bool as i32: pointee else: other_ty0
            if other_ty != self.ty_bool as i32:
                self.emit_error(f"`{self.type_name(other_ty0)}` does not combine with the mask `{type_text}`: a mask's other operand is a mask of its shape or a `bool` (§4.3d)", node)
                return 0
            if pointee == self.ty_bool as i32:
                let _ = self.record_contextual_copy_adjustment(other_node, pointee, other_ty0)
            self.vector_splats.insert(other_node, mask_ty)
        self.typed_expr_types.insert(node, mask_ty)
        mask_ty

    // The vector two lane-wise operands meet at (§4.2 per lane): the same
    // lane count and lane kind, one signedness, the wider lane; 0 if none.
    fn vector_common_type(a: i32, b: i32) -> i32:
        if self.vector_lane_count(a) != self.vector_lane_count(b): return 0
        let al = self.resolve_alias(self.vector_lane_type(a) as TypeId)
        let bl = self.resolve_alias(self.vector_lane_type(b) as TypeId)
        let ak = self.get_type_kind(al)
        if ak != self.get_type_kind(bl): return 0
        if ak == TypeKind.TY_INT and self.get_type_d1(al) != self.get_type_d1(bl): return 0
        if self.get_type_d0(al) >= self.get_type_d0(bl): a else: b

    // A scalar operand of a lane-wise operator: a number of the lane's kind
    // that the lane holds without loss (§4.2.6); a shift amount is any
    // integer.
    mut fn vector_scalar_operand_ok(node: i32, scalar_ty0: i32, vec_ty: i32, shift_amount: bool) -> bool:
        let pointee = self.shared_copy_pointee(scalar_ty0)
        let scalar_ty = if pointee != 0 and self.is_numeric_type(pointee): pointee else: scalar_ty0
        if pointee != 0 and scalar_ty == pointee:
            let _ = self.record_contextual_copy_adjustment(node, pointee, scalar_ty0)
        if not self.is_numeric_type(scalar_ty):
            self.emit_error(f"`{self.type_name(scalar_ty0)}` is not a lane of `{self.type_name(vec_ty)}`; a scalar operand broadcasts only as a number (§4.3d)", node)
            return false
        if shift_amount:
            if self.get_type_kind(self.resolve_alias(scalar_ty as TypeId)) != TypeKind.TY_INT:
                self.emit_error("a shift amount is an integer", node)
                return false
            return true
        not self.reject_implicit_numeric_narrowing(node, self.vector_lane_type(vec_ty), scalar_ty)

    // `-v` / `~v`: lane-wise (§4.2 per lane). -1 when the operand is no
    // vector.
    mut fn check_vector_unary(node: i32, op: i32, operand_node: i32, operand0: i32) -> i32:
        let operand = self.vector_value_type(operand_node, operand0)
        if self.is_mask_type(operand):
            // `not m` negates each lane (D80); nothing else is unary on a mask.
            if op == UnaryOp.UOP_BIT_NOT:
                self.emit_error("`~m` is refused: `not m` is the one spelling that negates a mask's lanes (§4.3d)", node)
                return 0
            if op != UnaryOp.UOP_NOT:
                self.emit_error("a mask is negated with `not m`; no other unary operator is defined on it (§4.3d)", node)
                return 0
            self.typed_expr_types.insert(node, operand)
            return operand
        if not self.is_vector_type(operand): return -1
        if op == UnaryOp.UOP_NOT:
            self.emit_error(f"`not` negates a mask or a bool, not `{self.type_name(operand)}`; `~v` flips integer lanes' bits (§4.3d)", node)
            return 0
        let lane = self.vector_lane_type(operand)
        if op == UnaryOp.UOP_NEGATE and self.is_unsigned_int_type(lane):
            self.emit_error("cannot negate an unsigned value", node)
            return 0
        if op == UnaryOp.UOP_BIT_NOT and self.vector_lane_is_float(operand):
            self.emit_error(f"`~` needs integer lanes; `{self.type_name(operand)}` has float lanes (§4.3d)", node)
            return 0
        if op != UnaryOp.UOP_NEGATE and op != UnaryOp.UOP_BIT_NOT:
            return -1
        self.typed_expr_types.insert(node, operand)
        operand

    // §4.3d: a literal in a vector context broadcasts to every lane. The
    // literal takes the lane type; the node's value is the vector.
    // §4.3d (v7.16): a `bool` literal in a mask context broadcasts
    // (`let m: m32x4 = true`); the mask type, or 0.
    fn mask_literal_context(node: i32) -> i32:
        if self.has_expected_type == 0 or self.expected_expr_type == 0: return 0
        let expected = self.expected_expr_type as i32
        if not self.is_mask_type(expected): return 0
        expected

    mut fn vector_literal_context_lane(node: i32) -> i32:
        if self.has_expected_type == 0 or self.expected_expr_type == 0: return 0
        let expected = self.expected_expr_type as i32
        if not self.is_vector_type(expected): return 0
        self.vector_lane_type(expected)

    // An owned demand for a vector (§4.2.6 per lane): an identical vector
    // passes; a lossless lane widening converts (recorded for MirLower); a
    // narrowing is refused. True when refused.
    mut fn reject_vector_narrowing(node: i32, expected: i32, actual0: i32) -> bool:
        let actual = self.vector_value_type(node, actual0)
        if not self.is_vector_type(expected) or not self.is_vector_type(actual): return false
        if self.types_identical(expected, actual): return false
        let want = self.type_name(expected)
        let got = self.type_name(actual)
        if self.vector_lane_count(expected) != self.vector_lane_count(actual):
            self.emit_error(f"`{got}` is not `{want}`: the lane counts differ (§4.3d)", node)
            return true
        let el = self.resolve_alias(self.vector_lane_type(expected) as TypeId)
        let al = self.resolve_alias(self.vector_lane_type(actual) as TypeId)
        let ek = self.get_type_kind(el)
        let ak = self.get_type_kind(al)
        var lossless = false
        if ek == TypeKind.TY_FLOAT and ak == TypeKind.TY_FLOAT:
            lossless = self.get_type_d0(el) > self.get_type_d0(al)
        else if ek == TypeKind.TY_INT and ak == TypeKind.TY_INT:
            lossless = self.int_narrowing_requires_cast(el, al) == 0
        if not lossless:
            self.emit_error(f"implicit narrowing or conversion from `{got}` to `{want}`; use an explicit `as` cast, which converts lane-wise (§4.3d, §4.2.6)", node)
            return true
        self.vector_conversions.insert(node, expected)
        false

    // `v as i32x4`: a lane-wise conversion between vectors of one lane
    // count (§4.3d); the bytes are reinterpreted only by `.bits()`. -1 when
    // neither side is a vector or a mask.
    mut fn check_vector_cast(node: i32, src: i32, target: i32) -> i32:
        if not self.is_vector_or_mask_type(src) and not self.is_vector_or_mask_type(target): return -1
        if self.is_vector_type(src) and self.is_vector_type(target) and self.vector_lane_count(src) == self.vector_lane_count(target):
            return target
        // `m as m8x4` converts a mask's width (D80).
        if self.is_mask_type(src) and self.is_mask_type(target) and self.vector_lane_count(src) == self.vector_lane_count(target):
            return target
        if self.is_mask_type(src) != self.is_mask_type(target) and self.is_vector_or_mask_type(src) and self.is_vector_or_mask_type(target):
            self.emit_error(f"a cast between the mask and vector `{self.type_name(src)}` and `{self.type_name(target)}` is refused: a true lane could be `1` or `-1`, two meanings (§4.3d); use `m.select(a, b)`", node)
            return 0
        self.emit_error(f"`as` converts a vector lane-wise to a vector of the same lane count, not `{self.type_name(src)}` to `{self.type_name(target)}`; `.bits()` reinterprets the bytes (§4.3d)", node)
        0

    // The broadcast a scalar never gets implicitly: `let v: f32x4 = s`.
    fn vector_scalar_binding_help(expected: i32, actual: i32) -> str:
        if not self.is_vector_type(expected) or not self.is_numeric_type(actual): return ""
        let type_text = self.type_name(expected)
        f"a scalar is not a vector: spell the broadcast `{type_text}.splat(s)` (§4.3d)"
