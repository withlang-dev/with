// Type — Type system infrastructure for the With compiler.
//
// Types are represented as integer-indexed entries in a TypeTable.
// Each type has a kind tag and up to 3 data fields, plus an extra
// array for variable-length data (struct fields, fn params, etc.).
//
// Builtin types are pre-registered at fixed indices (0-15).
// TypeId 0 is the error/sentinel type.
//
// Encoding by kind:
//   TK_ERROR:        no data
//   TK_UNIT:         no data
//   TK_BOOL:         no data
//   TK_INT:          d0=bits(8/16/32/64), d1=signed(1/0)
//   TK_FLOAT:        d0=bits(32/64)
//   TK_STR:          no data
//   TK_NEVER:        no data
//   TK_VOID:         no data
//   TK_STRUCT:       d0=name_sym, d1=extra_start, d2=field_count
//                    extra: [f1_name, f1_type, f1_has_default, ...]
//   TK_ENUM:         d0=name_sym, d1=extra_start, d2=variant_count
//                    extra: [v1_name, v1_payload_count, v1_p1_type, ...]
//   TK_ARRAY:        d0=elem_type, d1=size
//   TK_SLICE:        d0=elem_type
//   TK_TUPLE:        d0=extra_start, d1=elem_count
//                    extra: [e1_type, e2_type, ...]
//   TK_FN:           d0=extra_start, d1=param_count, d2=return_type
//                    extra: [is_variadic, p1_type, p2_type, ...]
//   TK_PTR:          d0=pointee_type, d1=is_mut(1/0)
//   TK_REF:          d0=pointee_type, d1=is_mut(1/0)
//   TK_ALIAS:        d0=name_sym, d1=target_type
//   TK_GENERIC_PARAM: d0=name_sym
//   TK_TRAIT_OBJ:    d0=trait_name_sym
//   TK_OPTION:       d0=payload_type
//   TK_RESULT:       d0=ok_type, d1=err_type
//   TK_RANGE:        d0=elem_type, d1=inclusive(1/0)

// ── Type kind constants ──────────────────────────────────────────────

fn TK_ERROR() -> i32: 0
fn TK_UNIT() -> i32: 1
fn TK_BOOL() -> i32: 2
fn TK_INT() -> i32: 3
fn TK_FLOAT() -> i32: 4
fn TK_I8() -> i32: 3
fn TK_I16() -> i32: 4
fn TK_I32() -> i32: 5
fn TK_I64() -> i32: 6
fn TK_U8() -> i32: 7
fn TK_U16() -> i32: 8
fn TK_U32() -> i32: 9
fn TK_U64() -> i32: 10
fn TK_F32() -> i32: 11
fn TK_F64() -> i32: 12
fn TK_STR() -> i32: 13
fn TK_NEVER() -> i32: 14
fn TK_VOID() -> i32: 15
fn TK_STRUCT() -> i32: 16
fn TK_ENUM() -> i32: 17
fn TK_ARRAY() -> i32: 18
fn TK_SLICE() -> i32: 19
fn TK_TUPLE() -> i32: 20
fn TK_FN() -> i32: 21
fn TK_PTR() -> i32: 22
fn TK_REF() -> i32: 23
fn TK_ALIAS() -> i32: 24
fn TK_GENERIC_PARAM() -> i32: 25
fn TK_TRAIT_OBJ() -> i32: 26
fn TK_OPTION() -> i32: 27
fn TK_RESULT() -> i32: 28
fn TK_RANGE() -> i32: 29

// ── Builtin type IDs (fixed indices) ────────────────────────────────
// These are pre-registered and always available.

fn TYPE_ERROR() -> i32: 0
fn TYPE_UNIT() -> i32: 1
fn TYPE_BOOL() -> i32: 2
fn TYPE_I8() -> i32: 3
fn TYPE_I16() -> i32: 4
fn TYPE_I32() -> i32: 5
fn TYPE_I64() -> i32: 6
fn TYPE_U8() -> i32: 7
fn TYPE_U16() -> i32: 8
fn TYPE_U32() -> i32: 9
fn TYPE_U64() -> i32: 10
fn TYPE_F32() -> i32: 11
fn TYPE_F64() -> i32: 12
fn TYPE_STR() -> i32: 13
fn TYPE_NEVER() -> i32: 14
fn TYPE_VOID() -> i32: 15

// Number of pre-registered builtin types.
fn BUILTIN_TYPE_COUNT() -> i32: 16

// ── TypeTable ────────────────────────────────────────────────────────

type TypeTable = {
    kinds: Vec[i32],
    data0: Vec[i32],
    data1: Vec[i32],
    data2: Vec[i32],
    extra: Vec[i32],
    named_types: HashMap[str, i32],
}

fn TypeTable.new() -> TypeTable:
    var tt = TypeTable {
        kinds: Vec.new(),
        data0: Vec.new(),
        data1: Vec.new(),
        data2: Vec.new(),
        extra: Vec.new(),
        named_types: HashMap.new(),
    }
    // Register all builtin types at fixed indices.
    // Index 0: error
    TypeTable.add_type(tt, TK_ERROR(), 0, 0, 0)
    // Index 1: unit
    TypeTable.add_type(tt, TK_UNIT(), 0, 0, 0)
    // Index 2: bool
    TypeTable.add_type(tt, TK_BOOL(), 0, 0, 0)
    // Index 3: i8
    TypeTable.add_type(tt, TK_INT(), 8, 1, 0)
    // Index 4: i16
    TypeTable.add_type(tt, TK_INT(), 16, 1, 0)
    // Index 5: i32
    TypeTable.add_type(tt, TK_INT(), 32, 1, 0)
    // Index 6: i64
    TypeTable.add_type(tt, TK_INT(), 64, 1, 0)
    // Index 7: u8
    TypeTable.add_type(tt, TK_INT(), 8, 0, 0)
    // Index 8: u16
    TypeTable.add_type(tt, TK_INT(), 16, 0, 0)
    // Index 9: u32
    TypeTable.add_type(tt, TK_INT(), 32, 0, 0)
    // Index 10: u64
    TypeTable.add_type(tt, TK_INT(), 64, 0, 0)
    // Index 11: f32
    TypeTable.add_type(tt, TK_FLOAT(), 32, 0, 0)
    // Index 12: f64
    TypeTable.add_type(tt, TK_FLOAT(), 64, 0, 0)
    // Index 13: str
    TypeTable.add_type(tt, TK_STR(), 0, 0, 0)
    // Index 14: never
    TypeTable.add_type(tt, TK_NEVER(), 0, 0, 0)
    // Index 15: void
    TypeTable.add_type(tt, TK_VOID(), 0, 0, 0)
    // Register named lookups for builtins.
    tt.named_types.insert("error", TYPE_ERROR())
    tt.named_types.insert("unit", TYPE_UNIT())
    tt.named_types.insert("bool", TYPE_BOOL())
    tt.named_types.insert("i8", TYPE_I8())
    tt.named_types.insert("i16", TYPE_I16())
    tt.named_types.insert("i32", TYPE_I32())
    tt.named_types.insert("i64", TYPE_I64())
    tt.named_types.insert("u8", TYPE_U8())
    tt.named_types.insert("u16", TYPE_U16())
    tt.named_types.insert("u32", TYPE_U32())
    tt.named_types.insert("u64", TYPE_U64())
    tt.named_types.insert("f32", TYPE_F32())
    tt.named_types.insert("f64", TYPE_F64())
    tt.named_types.insert("str", TYPE_STR())
    tt.named_types.insert("never", TYPE_NEVER())
    tt.named_types.insert("void", TYPE_VOID())
    tt

// ── Core operations ──────────────────────────────────────────────────

// Add a raw type entry. Returns the new TypeId.
fn TypeTable.add_type(self: TypeTable, kind: i32, d0: i32, d1: i32, d2: i32) -> i32:
    let id = self.kinds.len() as i32
    self.kinds.push(kind)
    self.data0.push(d0)
    self.data1.push(d1)
    self.data2.push(d2)
    id

// Add an extra data entry. Returns the index.
fn TypeTable.add_extra(self: TypeTable, val: i32) -> i32:
    let idx = self.extra.len() as i32
    self.extra.push(val)
    idx

fn TypeTable.type_count(self: TypeTable) -> i32:
    self.kinds.len() as i32

// ── Query operations ─────────────────────────────────────────────────

fn TypeTable.kind(self: TypeTable, type_id: i32) -> i32:
    self.kinds.get(type_id as i64)

fn TypeTable.get_data0(self: TypeTable, type_id: i32) -> i32:
    self.data0.get(type_id as i64)

fn TypeTable.get_data1(self: TypeTable, type_id: i32) -> i32:
    self.data1.get(type_id as i64)

fn TypeTable.get_data2(self: TypeTable, type_id: i32) -> i32:
    self.data2.get(type_id as i64)

fn TypeTable.get_extra(self: TypeTable, idx: i32) -> i32:
    self.extra.get(idx as i64)

// Look up a named type. Returns -1 if not found.
fn TypeTable.lookup(self: TypeTable, name: str) -> i32:
    let result = self.named_types.get(name)
    if result.is_some():
        return result.unwrap()
    -1

// Register a named type mapping.
fn TypeTable.register_name(self: TypeTable, name: str, type_id: i32) -> void:
    self.named_types.insert(name, type_id)

// ── Type constructors ────────────────────────────────────────────────

// Register a struct type.
// field_names, field_types, field_defaults are parallel arrays.
// field_defaults[i] is 1 if field i has a default, 0 otherwise.
// Returns the new TypeId.
fn TypeTable.add_struct(self: TypeTable, name_sym: i32, field_names: Vec[i32], field_types: Vec[i32], field_defaults: Vec[i32]) -> i32:
    let field_count = field_names.len() as i32
    let extra_start = self.extra.len() as i32
    var i = 0
    while i < field_count:
        self.extra.push(field_names.get(i as i64))
        self.extra.push(field_types.get(i as i64))
        self.extra.push(field_defaults.get(i as i64))
        i = i + 1
    TypeTable.add_type(self, TK_STRUCT(), name_sym, extra_start, field_count)

// Register an enum type.
// variant_names is a Vec of name symbols.
// variant_payloads is a Vec of payload counts (0 for unit variants).
// variant_payload_types is a flat Vec of all payload types in order.
// Returns the new TypeId.
fn TypeTable.add_enum(self: TypeTable, name_sym: i32, variant_names: Vec[i32], variant_payloads: Vec[i32], variant_payload_types: Vec[i32]) -> i32:
    let variant_count = variant_names.len() as i32
    let extra_start = self.extra.len() as i32
    var payload_idx = 0
    var i = 0
    while i < variant_count:
        self.extra.push(variant_names.get(i as i64))
        let pc = variant_payloads.get(i as i64)
        self.extra.push(pc)
        var j = 0
        while j < pc:
            self.extra.push(variant_payload_types.get(payload_idx as i64))
            payload_idx = payload_idx + 1
            j = j + 1
        i = i + 1
    TypeTable.add_type(self, TK_ENUM(), name_sym, extra_start, variant_count)

// Register an array type: [size]elem_type
fn TypeTable.add_array(self: TypeTable, elem_type: i32, size: i32) -> i32:
    TypeTable.add_type(self, TK_ARRAY(), elem_type, size, 0)

// Register a slice type: []elem_type
fn TypeTable.add_slice(self: TypeTable, elem_type: i32) -> i32:
    TypeTable.add_type(self, TK_SLICE(), elem_type, 0, 0)

// Register a tuple type: (T1, T2, ...)
fn TypeTable.add_tuple(self: TypeTable, elem_types: Vec[i32]) -> i32:
    let count = elem_types.len() as i32
    let extra_start = self.extra.len() as i32
    var i = 0
    while i < count:
        self.extra.push(elem_types.get(i as i64))
        i = i + 1
    TypeTable.add_type(self, TK_TUPLE(), extra_start, count, 0)

// Register a function type: fn(params) -> ret
fn TypeTable.add_fn(self: TypeTable, param_types: Vec[i32], return_type: i32, is_variadic: i32) -> i32:
    let count = param_types.len() as i32
    let extra_start = self.extra.len() as i32
    self.extra.push(is_variadic)
    var i = 0
    while i < count:
        self.extra.push(param_types.get(i as i64))
        i = i + 1
    TypeTable.add_type(self, TK_FN(), extra_start, count, return_type)

// Register a pointer type: *T or *mut T
fn TypeTable.add_ptr(self: TypeTable, pointee: i32, is_mut: i32) -> i32:
    TypeTable.add_type(self, TK_PTR(), pointee, is_mut, 0)

// Register a reference type: &T or &mut T
fn TypeTable.add_ref(self: TypeTable, pointee: i32, is_mut: i32) -> i32:
    TypeTable.add_type(self, TK_REF(), pointee, is_mut, 0)

// Register a type alias: type Name = Target
fn TypeTable.add_alias(self: TypeTable, name_sym: i32, target: i32) -> i32:
    TypeTable.add_type(self, TK_ALIAS(), name_sym, target, 0)

// Register a generic type parameter placeholder.
fn TypeTable.add_generic_param(self: TypeTable, name_sym: i32) -> i32:
    TypeTable.add_type(self, TK_GENERIC_PARAM(), name_sym, 0, 0)

// Register a trait object type: dyn Trait
fn TypeTable.add_trait_obj(self: TypeTable, trait_name_sym: i32) -> i32:
    TypeTable.add_type(self, TK_TRAIT_OBJ(), trait_name_sym, 0, 0)

// Register an Option type: Option[T]
fn TypeTable.add_option(self: TypeTable, payload_type: i32) -> i32:
    TypeTable.add_type(self, TK_OPTION(), payload_type, 0, 0)

// Register a Result type: Result[T, E]
fn TypeTable.add_result(self: TypeTable, ok_type: i32, err_type: i32) -> i32:
    TypeTable.add_type(self, TK_RESULT(), ok_type, err_type, 0)

// Register a range type: Range[T] (inclusive or exclusive)
fn TypeTable.add_range(self: TypeTable, elem_type: i32, inclusive: i32) -> i32:
    TypeTable.add_type(self, TK_RANGE(), elem_type, inclusive, 0)

// ── Type predicates ──────────────────────────────────────────────────

fn TypeTable.is_error(self: TypeTable, type_id: i32) -> bool:
    TypeTable.kind(self, type_id) == TK_ERROR()

fn TypeTable.is_int(self: TypeTable, type_id: i32) -> bool:
    let k = TypeTable.kind(self, type_id)
    k == TK_INT()

fn TypeTable.is_signed_int(self: TypeTable, type_id: i32) -> bool:
    if not TypeTable.is_int(self, type_id):
        return false
    TypeTable.get_data1(self, type_id) == 1

fn TypeTable.is_unsigned_int(self: TypeTable, type_id: i32) -> bool:
    if not TypeTable.is_int(self, type_id):
        return false
    TypeTable.get_data1(self, type_id) == 0

fn TypeTable.is_float(self: TypeTable, type_id: i32) -> bool:
    TypeTable.kind(self, type_id) == TK_FLOAT()

fn TypeTable.is_numeric(self: TypeTable, type_id: i32) -> bool:
    let k = TypeTable.kind(self, type_id)
    if k == TK_INT():
        return true
    k == TK_FLOAT()

fn TypeTable.is_bool(self: TypeTable, type_id: i32) -> bool:
    type_id == TYPE_BOOL()

fn TypeTable.is_str(self: TypeTable, type_id: i32) -> bool:
    type_id == TYPE_STR()

fn TypeTable.is_void(self: TypeTable, type_id: i32) -> bool:
    type_id == TYPE_VOID()

fn TypeTable.is_unit(self: TypeTable, type_id: i32) -> bool:
    type_id == TYPE_UNIT()

fn TypeTable.is_never(self: TypeTable, type_id: i32) -> bool:
    type_id == TYPE_NEVER()

fn TypeTable.is_struct(self: TypeTable, type_id: i32) -> bool:
    TypeTable.kind(self, type_id) == TK_STRUCT()

fn TypeTable.is_enum(self: TypeTable, type_id: i32) -> bool:
    TypeTable.kind(self, type_id) == TK_ENUM()

fn TypeTable.is_array(self: TypeTable, type_id: i32) -> bool:
    TypeTable.kind(self, type_id) == TK_ARRAY()

fn TypeTable.is_slice(self: TypeTable, type_id: i32) -> bool:
    TypeTable.kind(self, type_id) == TK_SLICE()

fn TypeTable.is_tuple(self: TypeTable, type_id: i32) -> bool:
    TypeTable.kind(self, type_id) == TK_TUPLE()

fn TypeTable.is_fn(self: TypeTable, type_id: i32) -> bool:
    TypeTable.kind(self, type_id) == TK_FN()

fn TypeTable.is_ptr(self: TypeTable, type_id: i32) -> bool:
    TypeTable.kind(self, type_id) == TK_PTR()

fn TypeTable.is_ref(self: TypeTable, type_id: i32) -> bool:
    TypeTable.kind(self, type_id) == TK_REF()

fn TypeTable.is_option(self: TypeTable, type_id: i32) -> bool:
    TypeTable.kind(self, type_id) == TK_OPTION()

fn TypeTable.is_result(self: TypeTable, type_id: i32) -> bool:
    TypeTable.kind(self, type_id) == TK_RESULT()

fn TypeTable.is_alias(self: TypeTable, type_id: i32) -> bool:
    TypeTable.kind(self, type_id) == TK_ALIAS()

fn TypeTable.is_generic_param(self: TypeTable, type_id: i32) -> bool:
    TypeTable.kind(self, type_id) == TK_GENERIC_PARAM()

fn TypeTable.is_trait_obj(self: TypeTable, type_id: i32) -> bool:
    TypeTable.kind(self, type_id) == TK_TRAIT_OBJ()

// Copy types: integers, floats, bool, raw pointers. From spec §2.3.
fn TypeTable.is_copy(self: TypeTable, type_id: i32) -> bool:
    let k = TypeTable.kind(self, type_id)
    if k == TK_INT():
        return true
    if k == TK_FLOAT():
        return true
    if k == TK_BOOL():
        return true
    if k == TK_PTR():
        return true
    if k == TK_UNIT():
        return true
    if k == TK_VOID():
        return true
    if k == TK_NEVER():
        return true
    false

// ── Struct field queries ─────────────────────────────────────────────

// Get field count of a struct type.
fn TypeTable.struct_field_count(self: TypeTable, type_id: i32) -> i32:
    TypeTable.get_data2(self, type_id)

// Get field name symbol at index for a struct type.
fn TypeTable.struct_field_name(self: TypeTable, type_id: i32, field_idx: i32) -> i32:
    let extra_start = TypeTable.get_data1(self, type_id)
    self.extra.get((extra_start + field_idx * 3) as i64)

// Get field type at index for a struct type.
fn TypeTable.struct_field_type(self: TypeTable, type_id: i32, field_idx: i32) -> i32:
    let extra_start = TypeTable.get_data1(self, type_id)
    self.extra.get((extra_start + field_idx * 3 + 1) as i64)

// Get whether field has a default at index for a struct type.
fn TypeTable.struct_field_has_default(self: TypeTable, type_id: i32, field_idx: i32) -> i32:
    let extra_start = TypeTable.get_data1(self, type_id)
    self.extra.get((extra_start + field_idx * 3 + 2) as i64)

// Get struct name symbol.
fn TypeTable.struct_name(self: TypeTable, type_id: i32) -> i32:
    TypeTable.get_data0(self, type_id)

// ── Enum queries ─────────────────────────────────────────────────────

// Get variant count of an enum type.
fn TypeTable.enum_variant_count(self: TypeTable, type_id: i32) -> i32:
    TypeTable.get_data2(self, type_id)

// Get enum name symbol.
fn TypeTable.enum_name(self: TypeTable, type_id: i32) -> i32:
    TypeTable.get_data0(self, type_id)

// Walk the extra data to find variant at given index.
// Returns the extra index where that variant's data starts.
fn TypeTable.enum_variant_extra(self: TypeTable, type_id: i32, variant_idx: i32) -> i32:
    let extra_start = TypeTable.get_data1(self, type_id)
    var pos = extra_start
    var i = 0
    while i < variant_idx:
        // skip name
        pos = pos + 1
        // read payload count, skip that many payload types
        let pc = self.extra.get(pos as i64)
        pos = pos + 1 + pc
        i = i + 1
    pos

// Get variant name symbol at index.
fn TypeTable.enum_variant_name(self: TypeTable, type_id: i32, variant_idx: i32) -> i32:
    let pos = TypeTable.enum_variant_extra(self, type_id, variant_idx)
    self.extra.get(pos as i64)

// Get variant payload count at index.
fn TypeTable.enum_variant_payload_count(self: TypeTable, type_id: i32, variant_idx: i32) -> i32:
    let pos = TypeTable.enum_variant_extra(self, type_id, variant_idx)
    self.extra.get((pos + 1) as i64)

// Get variant payload type at (variant_idx, payload_idx).
fn TypeTable.enum_variant_payload_type(self: TypeTable, type_id: i32, variant_idx: i32, payload_idx: i32) -> i32:
    let pos = TypeTable.enum_variant_extra(self, type_id, variant_idx)
    self.extra.get((pos + 2 + payload_idx) as i64)

// ── Fn type queries ──────────────────────────────────────────────────

// Get param count of a fn type.
fn TypeTable.fn_param_count(self: TypeTable, type_id: i32) -> i32:
    TypeTable.get_data1(self, type_id)

// Get return type of a fn type.
fn TypeTable.fn_return_type(self: TypeTable, type_id: i32) -> i32:
    TypeTable.get_data2(self, type_id)

// Get whether a fn type is variadic.
fn TypeTable.fn_is_variadic(self: TypeTable, type_id: i32) -> i32:
    let extra_start = TypeTable.get_data0(self, type_id)
    self.extra.get(extra_start as i64)

// Get param type at index for a fn type.
fn TypeTable.fn_param_type(self: TypeTable, type_id: i32, param_idx: i32) -> i32:
    let extra_start = TypeTable.get_data0(self, type_id)
    // extra: [is_variadic, p1_type, p2_type, ...]
    self.extra.get((extra_start + 1 + param_idx) as i64)

// ── Tuple queries ────────────────────────────────────────────────────

fn TypeTable.tuple_elem_count(self: TypeTable, type_id: i32) -> i32:
    TypeTable.get_data1(self, type_id)

fn TypeTable.tuple_elem_type(self: TypeTable, type_id: i32, elem_idx: i32) -> i32:
    let extra_start = TypeTable.get_data0(self, type_id)
    self.extra.get((extra_start + elem_idx) as i64)

// ── Array/Slice queries ──────────────────────────────────────────────

fn TypeTable.array_elem_type(self: TypeTable, type_id: i32) -> i32:
    TypeTable.get_data0(self, type_id)

fn TypeTable.array_size(self: TypeTable, type_id: i32) -> i32:
    TypeTable.get_data1(self, type_id)

fn TypeTable.slice_elem_type(self: TypeTable, type_id: i32) -> i32:
    TypeTable.get_data0(self, type_id)

// ── Ptr/Ref queries ──────────────────────────────────────────────────

fn TypeTable.pointee_type(self: TypeTable, type_id: i32) -> i32:
    TypeTable.get_data0(self, type_id)

fn TypeTable.is_mut_ptr(self: TypeTable, type_id: i32) -> bool:
    TypeTable.get_data1(self, type_id) == 1

fn TypeTable.is_mut_ref(self: TypeTable, type_id: i32) -> bool:
    TypeTable.get_data1(self, type_id) == 1

// ── Alias queries ────────────────────────────────────────────────────

fn TypeTable.alias_target(self: TypeTable, type_id: i32) -> i32:
    TypeTable.get_data1(self, type_id)

// Resolve through aliases to the underlying type.
fn TypeTable.resolve_alias(self: TypeTable, type_id: i32) -> i32:
    var tid = type_id
    var depth = 0
    while TypeTable.kind(self, tid) == TK_ALIAS():
        tid = TypeTable.alias_target(self, tid)
        depth = depth + 1
        if depth > 32:
            return TYPE_ERROR()
    tid

// ── Option/Result queries ────────────────────────────────────────────

fn TypeTable.option_payload(self: TypeTable, type_id: i32) -> i32:
    TypeTable.get_data0(self, type_id)

fn TypeTable.result_ok_type(self: TypeTable, type_id: i32) -> i32:
    TypeTable.get_data0(self, type_id)

fn TypeTable.result_err_type(self: TypeTable, type_id: i32) -> i32:
    TypeTable.get_data1(self, type_id)

// ── Range queries ────────────────────────────────────────────────────

fn TypeTable.range_elem_type(self: TypeTable, type_id: i32) -> i32:
    TypeTable.get_data0(self, type_id)

fn TypeTable.range_is_inclusive(self: TypeTable, type_id: i32) -> bool:
    TypeTable.get_data1(self, type_id) == 1

// ── Generic param queries ────────────────────────────────────────────

fn TypeTable.generic_param_name(self: TypeTable, type_id: i32) -> i32:
    TypeTable.get_data0(self, type_id)

// ── Trait object queries ─────────────────────────────────────────────

fn TypeTable.trait_obj_name(self: TypeTable, type_id: i32) -> i32:
    TypeTable.get_data0(self, type_id)

// ── Type name resolution ─────────────────────────────────────────────

// Resolve a type name string to a TypeId. Returns TYPE_ERROR() if not found.
fn TypeTable.resolve_name(self: TypeTable, name: str) -> i32:
    let result = TypeTable.lookup(self, name)
    if result >= 0:
        return result
    TYPE_ERROR()

// ── Int bit width queries ────────────────────────────────────────────

fn TypeTable.int_bits(self: TypeTable, type_id: i32) -> i32:
    TypeTable.get_data0(self, type_id)

fn TypeTable.int_is_signed(self: TypeTable, type_id: i32) -> bool:
    TypeTable.get_data1(self, type_id) == 1

fn TypeTable.float_bits(self: TypeTable, type_id: i32) -> i32:
    TypeTable.get_data0(self, type_id)

// ── Type equality ────────────────────────────────────────────────────

// Check structural equality of two types.
// For builtins and named types, this is just TypeId equality.
// For compound types, we check recursively.
fn TypeTable.types_equal(self: TypeTable, a: i32, b: i32) -> bool:
    if a == b:
        return true
    let ka = TypeTable.kind(self, a)
    let kb = TypeTable.kind(self, b)
    if ka != kb:
        return false
    // For structural types, compare data fields.
    if ka == TK_ARRAY():
        if not TypeTable.types_equal(self, TypeTable.get_data0(self, a), TypeTable.get_data0(self, b)):
            return false
        return TypeTable.get_data1(self, a) == TypeTable.get_data1(self, b)
    if ka == TK_SLICE():
        return TypeTable.types_equal(self, TypeTable.get_data0(self, a), TypeTable.get_data0(self, b))
    if ka == TK_PTR():
        if TypeTable.get_data1(self, a) != TypeTable.get_data1(self, b):
            return false
        return TypeTable.types_equal(self, TypeTable.get_data0(self, a), TypeTable.get_data0(self, b))
    if ka == TK_REF():
        if TypeTable.get_data1(self, a) != TypeTable.get_data1(self, b):
            return false
        return TypeTable.types_equal(self, TypeTable.get_data0(self, a), TypeTable.get_data0(self, b))
    if ka == TK_OPTION():
        return TypeTable.types_equal(self, TypeTable.get_data0(self, a), TypeTable.get_data0(self, b))
    if ka == TK_RESULT():
        if not TypeTable.types_equal(self, TypeTable.get_data0(self, a), TypeTable.get_data0(self, b)):
            return false
        return TypeTable.types_equal(self, TypeTable.get_data1(self, a), TypeTable.get_data1(self, b))
    // For named types (struct, enum), identity is TypeId.
    false

// ── FnInfo & VarInfo (used by Sema) ─────────────────────────────────

// Variable state for move tracking.
fn VS_LIVE() -> i32: 0
fn VS_MOVED() -> i32: 1

type VarInfo = {
    name: i32,
    type_id: i32,
    is_mutable: i32,
    state: i32,
    moved_span_start: i32,
    moved_span_end: i32,
}

fn VarInfo.new(name: i32, type_id: i32, is_mutable: i32) -> VarInfo:
    VarInfo {
        name: name,
        type_id: type_id,
        is_mutable: is_mutable,
        state: VS_LIVE(),
        moved_span_start: 0,
        moved_span_end: 0,
    }

type FnInfo = {
    name: i32,
    type_id: i32,
    return_type: i32,
    param_count: i32,
    is_generic: i32,
    type_param_count: i32,
    extra_start: i32,
}

// Scope for variable lookup.
type Scope = {
    vars: HashMap[str, i32],
    parent_idx: i32,
}

fn Scope.new(parent_idx: i32) -> Scope:
    Scope {
        vars: HashMap.new(),
        parent_idx: parent_idx,
    }
