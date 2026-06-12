use Sema
use Ast

fn type_layout_align_up(offset: i64, align: i64) -> i64:
    if align <= 1:
        return offset
    let rem = offset % align
    if rem == 0:
        return offset
    offset + (align - rem)

fn type_layout_int_bytes(bits: i32) -> i64:
    if bits <= 0:
        return 4
    let bytes = bits / 8
    if bytes <= 0:
        return 1
    bytes as i64

fn Sema.type_layout_struct_sub_kind(self: Sema, name_sym: i32) -> i32:
    if name_sym != 0 and self.type_decl_nodes.contains(name_sym):
        let decl = self.type_decl_nodes.get(name_sym).unwrap()
        return type_decl_sub_kind(self.ast.get_data2(decl))
    TypeDeclKind.Struct

fn Sema.type_layout_generic_struct_field_count(self: Sema, tid: i32) -> i32:
    let resolved = self.resolve_alias(tid)
    if self.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
        return 0
    let base_sym = self.get_type_d0(resolved)
    if not self.type_decl_nodes.contains(base_sym):
        return 0
    let decl = self.type_decl_nodes.get(base_sym).unwrap()
    let sub_kind = type_decl_sub_kind(self.ast.get_data2(decl))
    if sub_kind != TypeDeclKind.Struct and sub_kind != TypeDeclKind.Union:
        return 0
    self.ast.get_extra(self.ast.get_data1(decl))

fn Sema.type_layout_generic_struct_field_type(self: Sema, tid: i32, field_index: i32) -> i32:
    let resolved = self.resolve_alias(tid)
    if self.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
        return 0
    let base_sym = self.get_type_d0(resolved)
    if not self.type_decl_nodes.contains(base_sym):
        return 0
    let decl = self.type_decl_nodes.get(base_sym).unwrap()
    let extra_start = self.ast.get_data1(decl)
    let field_count = self.ast.get_extra(extra_start)
    if field_index < 0 or field_index >= field_count:
        return 0
    if self.setup_generic_inst_substitution(resolved as i32, base_sym) == 0:
        if self.named_types.contains(base_sym):
            let base_tid = self.named_types.get(base_sym).unwrap()
            let te_start = self.get_type_d1(base_tid)
            return self.type_extra.get((te_start + field_index * 3 + 1) as i64)
        return 0
    let tp_start = self.type_decl_tp_start(decl)
    let tp_count = self.type_decl_tp_count(decl)
    let field_type_node = self.ast.get_extra(extra_start + 1 + field_index * 3 + 1)
    self.resolve_generic_return_type_node(field_type_node, tp_start, tp_count)

fn Sema.type_layout_generic_struct_field_align(self: Sema, tid: i32, field_index: i32) -> i64:
    let field_tid = self.type_layout_generic_struct_field_type(tid, field_index)
    self.type_layout_align_of(field_tid)

fn Sema.type_layout_struct_field_align(self: Sema, tid: i32, field_index: i32) -> i64:
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_GENERIC_INST:
        return self.type_layout_generic_struct_field_align(resolved as i32, field_index)
    if tk != TypeKind.TY_STRUCT:
        return 1
    let te_start = self.get_type_d1(resolved)
    let field_count = self.get_type_d2(resolved)
    if field_index < 0 or field_index >= field_count:
        return 1
    let field_tid = self.type_extra.get((te_start + field_index * 3 + 1) as i64)
    let natural = self.type_layout_align_of(field_tid)
    let align_slot = te_start + field_count * 3 + field_index
    if align_slot >= 0 and align_slot < self.type_extra.len() as i32:
        let explicit = self.type_extra.get(align_slot as i64)
        if explicit > 0:
            return explicit as i64
    natural

fn Sema.type_layout_struct_field_offset(self: Sema, tid: i32, field_index: i32) -> i64:
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_GENERIC_INST:
        var offset: i64 = 0
        for fi in 0..field_index:
            let field_align = self.type_layout_generic_struct_field_align(resolved as i32, fi)
            offset = type_layout_align_up(offset, field_align)
            offset = offset + self.type_layout_size_of(self.type_layout_generic_struct_field_type(resolved as i32, fi))
        return type_layout_align_up(offset, self.type_layout_generic_struct_field_align(resolved as i32, field_index))
    if tk != TypeKind.TY_STRUCT:
        return 0
    let name_sym = self.get_type_d0(resolved)
    if self.distinct_type_names.contains(name_sym):
        return 0
    if self.type_layout_struct_sub_kind(name_sym) == TypeDeclKind.Union:
        return 0
    var offset: i64 = 0
    for fi in 0..field_index:
        let field_align = self.type_layout_struct_field_align(resolved as i32, fi)
        offset = type_layout_align_up(offset, field_align)
        let te_start = self.get_type_d1(resolved)
        let field_tid = self.type_extra.get((te_start + fi * 3 + 1) as i64)
        offset = offset + self.type_layout_size_of(field_tid)
    type_layout_align_up(offset, self.type_layout_struct_field_align(resolved as i32, field_index))

fn Sema.type_layout_struct_align_of(self: Sema, tid: i32) -> i64:
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_GENERIC_INST:
        let field_count = self.type_layout_generic_struct_field_count(resolved as i32)
        var max_align: i64 = 1
        for fi in 0..field_count:
            let field_align = self.type_layout_generic_struct_field_align(resolved as i32, fi)
            if field_align > max_align:
                max_align = field_align
        return max_align
    if tk != TypeKind.TY_STRUCT:
        return 1
    let name_sym = self.get_type_d0(resolved)
    if self.distinct_type_names.contains(name_sym):
        let te_start = self.get_type_d1(resolved)
        return self.type_layout_align_of(self.type_extra.get((te_start + 1) as i64))
    let field_count = self.get_type_d2(resolved)
    if field_count <= 0:
        return 1
    var max_align: i64 = 1
    for fi in 0..field_count:
        let field_align = self.type_layout_struct_field_align(resolved as i32, fi)
        if field_align > max_align:
            max_align = field_align
    max_align

fn Sema.type_layout_struct_size_of(self: Sema, tid: i32) -> i64:
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = self.get_type_d0(resolved)
        if base_sym != 0 and self.type_decl_nodes.contains(base_sym):
            let decl = self.type_decl_nodes.get(base_sym).unwrap()
            if type_decl_sub_kind(self.ast.get_data2(decl)) == TypeDeclKind.Union:
                var max_size: i64 = 0
                var max_align: i64 = 1
                for fi in 0..self.type_layout_generic_struct_field_count(resolved as i32):
                    let field_tid = self.type_layout_generic_struct_field_type(resolved as i32, fi)
                    let field_size = self.type_layout_size_of(field_tid)
                    let field_align = self.type_layout_align_of(field_tid)
                    if field_size > max_size:
                        max_size = field_size
                    if field_align > max_align:
                        max_align = field_align
                if max_size == 0:
                    return 1
                return type_layout_align_up(max_size, max_align)
        let field_count = self.type_layout_generic_struct_field_count(resolved as i32)
        var offset: i64 = 0
        var max_align: i64 = 1
        for fi in 0..field_count:
            let field_align = self.type_layout_generic_struct_field_align(resolved as i32, fi)
            if field_align > max_align:
                max_align = field_align
            offset = type_layout_align_up(offset, field_align)
            offset = offset + self.type_layout_size_of(self.type_layout_generic_struct_field_type(resolved as i32, fi))
        return type_layout_align_up(offset, max_align)
    if tk != TypeKind.TY_STRUCT:
        return 0
    let name_sym = self.get_type_d0(resolved)
    if self.distinct_type_names.contains(name_sym):
        let te_start = self.get_type_d1(resolved)
        return self.type_layout_size_of(self.type_extra.get((te_start + 1) as i64))
    let sub_kind = self.type_layout_struct_sub_kind(name_sym)
    let field_count = self.get_type_d2(resolved)
    if sub_kind == TypeDeclKind.Union:
        var max_size: i64 = 0
        var max_align: i64 = 1
        for fi in 0..field_count:
            let te_start = self.get_type_d1(resolved)
            let field_tid = self.type_extra.get((te_start + fi * 3 + 1) as i64)
            let field_size = self.type_layout_size_of(field_tid)
            let field_align = self.type_layout_struct_field_align(resolved as i32, fi)
            if field_size > max_size:
                max_size = field_size
            if field_align > max_align:
                max_align = field_align
        if max_size == 0:
            return 1
        return type_layout_align_up(max_size, max_align)
    if field_count <= 0:
        return 0
    var offset: i64 = 0
    let te_start = self.get_type_d1(resolved)
    for fi in 0..field_count:
        let field_align = self.type_layout_struct_field_align(resolved as i32, fi)
        offset = type_layout_align_up(offset, field_align)
        let field_tid = self.type_extra.get((te_start + fi * 3 + 1) as i64)
        offset = offset + self.type_layout_size_of(field_tid)
    type_layout_align_up(offset, self.type_layout_struct_align_of(resolved as i32))

fn Sema.type_layout_enum_align_of(self: Sema, tid: i32) -> i64:
    let resolved = self.resolve_alias(tid)
    if self.get_type_kind(resolved) == TypeKind.TY_GENERIC_INST:
        let base_sym = self.get_generic_inst_base(resolved as i32)
        if self.named_types.contains(base_sym):
            return self.type_layout_enum_align_of(self.named_types.get(base_sym).unwrap())
        return 4
    if self.get_type_kind(resolved) != TypeKind.TY_ENUM:
        return 1
    let repr = self.enum_repr_type(resolved as i32)
    if repr != 0:
        return self.type_layout_align_of(repr)
    4

fn Sema.type_layout_enum_size_of(self: Sema, tid: i32) -> i64:
    let resolved = self.resolve_alias(tid)
    if self.get_type_kind(resolved) == TypeKind.TY_GENERIC_INST:
        let base_sym = self.get_generic_inst_base(resolved as i32)
        if not self.named_types.contains(base_sym):
            return 0
        let base_tid = self.named_types.get(base_sym).unwrap()
        if self.get_type_kind(base_tid) != TypeKind.TY_ENUM:
            return 0
        let te_start = self.get_type_d1(base_tid)
        let variant_count = self.get_type_d2(base_tid)
        var max_payload_size: i64 = 0
        var pos = te_start
        for _ in 0..variant_count:
            let name_sym = self.type_extra.get(pos as i64)
            let payload_count = self.type_extra.get((pos + 1) as i64)
            let payload_types = self.resolve_generic_enum_payload(resolved as i32, base_sym, name_sym, payload_count)
            if payload_count > 0:
                var payload_size: i64 = 0
                var payload_align: i64 = 1
                for pi in 0..payload_count:
                    let payload_tid = if pi < payload_types.len() as i32: payload_types.get(pi as i64) else: self.type_extra.get((pos + 2 + pi) as i64)
                    let align = self.type_layout_align_of(payload_tid)
                    payload_align = if align > payload_align: align else: payload_align
                    payload_size = type_layout_align_up(payload_size, align)
                    payload_size = payload_size + self.type_layout_size_of(payload_tid)
                payload_size = type_layout_align_up(payload_size, payload_align)
                if payload_size > max_payload_size:
                    max_payload_size = payload_size
            pos = pos + 2 + payload_count
        let tag_tid = self.enum_repr_type(base_tid)
        let tag_size = if tag_tid != 0: self.type_layout_size_of(tag_tid) else: 4
        let enum_align = if tag_tid != 0: self.type_layout_align_of(tag_tid) else: 4
        return type_layout_align_up(tag_size + max_payload_size, enum_align)
    if self.get_type_kind(resolved) != TypeKind.TY_ENUM:
        return 0
    let te_start = self.get_type_d1(resolved)
    let variant_count = self.get_type_d2(resolved)
    var max_payload_size: i64 = 0
    var pos = te_start
    for _ in 0..variant_count:
        let payload_count = self.type_extra.get((pos + 1) as i64)
        if payload_count > 0:
            var payload_size: i64 = 0
            var payload_align: i64 = 1
            for pi in 0..payload_count:
                let payload_tid = self.type_extra.get((pos + 2 + pi) as i64)
                let align = self.type_layout_align_of(payload_tid)
                payload_align = if align > payload_align: align else: payload_align
                payload_size = type_layout_align_up(payload_size, align)
                payload_size = payload_size + self.type_layout_size_of(payload_tid)
            payload_size = type_layout_align_up(payload_size, payload_align)
            if payload_size > max_payload_size:
                max_payload_size = payload_size
        pos = pos + 2 + payload_count
    let tag_tid = self.enum_repr_type(resolved as i32)
    let tag_size = if tag_tid != 0: self.type_layout_size_of(tag_tid) else: 4
    let enum_align = if tag_tid != 0: self.type_layout_align_of(tag_tid) else: 4
    type_layout_align_up(tag_size + max_payload_size, enum_align)

fn Sema.type_layout_align_of(self: Sema, tid: i32) -> i64:
    if tid == 0:
        return 1
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_INT:
        return type_layout_int_bytes(self.get_type_d0(resolved))
    if tk == TypeKind.TY_FLOAT:
        return type_layout_int_bytes(self.get_type_d0(resolved))
    if tk == TypeKind.TY_BOOL:
        return 1
    if tk == TypeKind.TY_VOID or tk == TypeKind.TY_NEVER or tk == TypeKind.TY_ERR:
        return 1
    if tk == TypeKind.TY_STR or tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF or tk == TypeKind.TY_FN or tk == TypeKind.TY_EXTERN_FN or tk == TypeKind.TY_GENERIC_FN or tk == TypeKind.TY_TRAIT_OBJ:
        return 8
    if tk == TypeKind.TY_ARRAY:
        return self.type_layout_align_of(self.get_type_d0(resolved))
    if tk == TypeKind.TY_SLICE:
        return 8
    if tk == TypeKind.TY_TUPLE:
        let te_start = self.get_type_d0(resolved)
        let elem_count = self.get_type_d1(resolved)
        var max_align: i64 = 1
        for ei in 0..elem_count:
            let align = self.type_layout_align_of(self.type_extra.get((te_start + ei) as i64))
            if align > max_align:
                max_align = align
        return max_align
    if tk == TypeKind.TY_RANGE:
        let elem_align = self.type_layout_align_of(self.get_type_d0(resolved))
        if elem_align > 1:
            return elem_align
        return 1
    if tk == TypeKind.TY_STRUCT:
        return self.type_layout_struct_align_of(resolved as i32)
    if tk == TypeKind.TY_ENUM:
        return self.type_layout_enum_align_of(resolved as i32)
    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = self.get_generic_inst_base(resolved as i32)
        if self.named_types.contains(base_sym):
            let base_tid = self.named_types.get(base_sym).unwrap()
            let base_kind = self.get_type_kind(self.resolve_alias(base_tid))
            if base_kind == TypeKind.TY_STRUCT:
                return self.type_layout_struct_align_of(resolved as i32)
            if base_kind == TypeKind.TY_ENUM:
                return self.type_layout_enum_align_of(resolved as i32)
        return 8
    1

fn Sema.type_layout_size_of(self: Sema, tid: i32) -> i64:
    if tid == 0:
        return 0
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_INT:
        return type_layout_int_bytes(self.get_type_d0(resolved))
    if tk == TypeKind.TY_FLOAT:
        return type_layout_int_bytes(self.get_type_d0(resolved))
    if tk == TypeKind.TY_BOOL:
        return 1
    if tk == TypeKind.TY_VOID or tk == TypeKind.TY_NEVER or tk == TypeKind.TY_ERR:
        return 0
    if tk == TypeKind.TY_STR or tk == TypeKind.TY_SLICE:
        return 16
    if tk == TypeKind.TY_FN:
        return 16
    if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF or tk == TypeKind.TY_EXTERN_FN or tk == TypeKind.TY_GENERIC_FN or tk == TypeKind.TY_TRAIT_OBJ:
        return 8
    if tk == TypeKind.TY_ARRAY:
        return self.type_layout_size_of(self.get_type_d0(resolved)) * self.get_type_d1(resolved) as i64
    if tk == TypeKind.TY_TUPLE:
        let te_start = self.get_type_d0(resolved)
        let elem_count = self.get_type_d1(resolved)
        var offset: i64 = 0
        var max_align: i64 = 1
        for ei in 0..elem_count:
            let elem_tid = self.type_extra.get((te_start + ei) as i64)
            let align = self.type_layout_align_of(elem_tid)
            if align > max_align:
                max_align = align
            offset = type_layout_align_up(offset, align)
            offset = offset + self.type_layout_size_of(elem_tid)
        return type_layout_align_up(offset, max_align)
    if tk == TypeKind.TY_RANGE:
        let elem_tid = self.get_type_d0(resolved)
        let elem_align = self.type_layout_align_of(elem_tid)
        let elem_size = self.type_layout_size_of(elem_tid)
        let end_offset = type_layout_align_up(elem_size, elem_align)
        let flag_offset = type_layout_align_up(end_offset + elem_size, 1)
        return type_layout_align_up(flag_offset + 1, if elem_align > 1: elem_align else: 1)
    if tk == TypeKind.TY_STRUCT:
        return self.type_layout_struct_size_of(resolved as i32)
    if tk == TypeKind.TY_ENUM:
        return self.type_layout_enum_size_of(resolved as i32)
    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = self.get_generic_inst_base(resolved as i32)
        if self.named_types.contains(base_sym):
            let base_tid = self.named_types.get(base_sym).unwrap()
            let base_kind = self.get_type_kind(self.resolve_alias(base_tid))
            if base_kind == TypeKind.TY_STRUCT:
                return self.type_layout_struct_size_of(resolved as i32)
            if base_kind == TypeKind.TY_ENUM:
                return self.type_layout_enum_size_of(resolved as i32)
        return 0
    0
