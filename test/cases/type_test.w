//! expect-stdout: ok

use Type

fn test_builtins:
    var tt = TypeTable.new()
    // Verify builtin count
    assert(TypeTable.type_count(tt) == BUILTIN_TYPE_COUNT())

    // Verify builtin type kinds
    assert(TypeTable.kind(tt, TYPE_ERROR()) == TK_ERROR())
    assert(TypeTable.kind(tt, TYPE_UNIT()) == TK_UNIT())
    assert(TypeTable.kind(tt, TYPE_BOOL()) == TK_BOOL())
    assert(TypeTable.kind(tt, TYPE_I32()) == TK_INT())
    assert(TypeTable.kind(tt, TYPE_I64()) == TK_INT())
    assert(TypeTable.kind(tt, TYPE_U8()) == TK_INT())
    assert(TypeTable.kind(tt, TYPE_F32()) == TK_FLOAT())
    assert(TypeTable.kind(tt, TYPE_F64()) == TK_FLOAT())
    assert(TypeTable.kind(tt, TYPE_STR()) == TK_STR())
    assert(TypeTable.kind(tt, TYPE_NEVER()) == TK_NEVER())
    assert(TypeTable.kind(tt, TYPE_VOID()) == TK_VOID())

    // Verify int details
    assert(TypeTable.int_bits(tt, TYPE_I8()) == 8)
    assert(TypeTable.int_is_signed(tt, TYPE_I8()))
    assert(TypeTable.int_bits(tt, TYPE_I32()) == 32)
    assert(TypeTable.int_is_signed(tt, TYPE_I32()))
    assert(TypeTable.int_bits(tt, TYPE_U64()) == 64)
    assert(not TypeTable.int_is_signed(tt, TYPE_U64()))

    // Verify float details
    assert(TypeTable.float_bits(tt, TYPE_F32()) == 32)
    assert(TypeTable.float_bits(tt, TYPE_F64()) == 64)

fn test_named_lookup:
    var tt = TypeTable.new()
    assert(TypeTable.lookup(tt, "i32") == TYPE_I32())
    assert(TypeTable.lookup(tt, "bool") == TYPE_BOOL())
    assert(TypeTable.lookup(tt, "str") == TYPE_STR())
    assert(TypeTable.lookup(tt, "void") == TYPE_VOID())
    assert(TypeTable.lookup(tt, "nonexistent") == -1)
    assert(TypeTable.resolve_name(tt, "i32") == TYPE_I32())
    assert(TypeTable.resolve_name(tt, "nonexistent") == TYPE_ERROR())

fn test_predicates:
    var tt = TypeTable.new()
    assert(TypeTable.is_int(tt, TYPE_I32()))
    assert(not TypeTable.is_int(tt, TYPE_BOOL()))
    assert(TypeTable.is_signed_int(tt, TYPE_I32()))
    assert(TypeTable.is_unsigned_int(tt, TYPE_U32()))
    assert(TypeTable.is_float(tt, TYPE_F64()))
    assert(TypeTable.is_numeric(tt, TYPE_I32()))
    assert(TypeTable.is_numeric(tt, TYPE_F64()))
    assert(not TypeTable.is_numeric(tt, TYPE_BOOL()))
    assert(TypeTable.is_bool(tt, TYPE_BOOL()))
    assert(TypeTable.is_str(tt, TYPE_STR()))
    assert(TypeTable.is_void(tt, TYPE_VOID()))
    assert(TypeTable.is_copy(tt, TYPE_I32()))
    assert(TypeTable.is_copy(tt, TYPE_BOOL()))
    assert(not TypeTable.is_copy(tt, TYPE_STR()))

fn test_struct_type:
    var tt = TypeTable.new()
    var names = Vec.new()
    names.push(100)
    names.push(101)
    var types = Vec.new()
    types.push(TYPE_I32())
    types.push(TYPE_F64())
    var defaults = Vec.new()
    defaults.push(0)
    defaults.push(1)
    let sid = TypeTable.add_struct(tt, 200, names, types, defaults)
    assert(TypeTable.is_struct(tt, sid))
    assert(TypeTable.struct_field_count(tt, sid) == 2)
    assert(TypeTable.struct_name(tt, sid) == 200)
    assert(TypeTable.struct_field_name(tt, sid, 0) == 100)
    assert(TypeTable.struct_field_name(tt, sid, 1) == 101)
    assert(TypeTable.struct_field_type(tt, sid, 0) == TYPE_I32())
    assert(TypeTable.struct_field_type(tt, sid, 1) == TYPE_F64())
    assert(TypeTable.struct_field_has_default(tt, sid, 0) == 0)
    assert(TypeTable.struct_field_has_default(tt, sid, 1) == 1)
    assert(not TypeTable.is_copy(tt, sid))

fn test_enum_type:
    var tt = TypeTable.new()
    var vnames = Vec.new()
    vnames.push(300)
    vnames.push(301)
    var vpayloads = Vec.new()
    vpayloads.push(0)
    vpayloads.push(1)
    var vptypes = Vec.new()
    vptypes.push(TYPE_I32())
    let eid = TypeTable.add_enum(tt, 400, vnames, vpayloads, vptypes)
    assert(TypeTable.is_enum(tt, eid))
    assert(TypeTable.enum_variant_count(tt, eid) == 2)
    assert(TypeTable.enum_name(tt, eid) == 400)
    assert(TypeTable.enum_variant_name(tt, eid, 0) == 300)
    assert(TypeTable.enum_variant_name(tt, eid, 1) == 301)
    assert(TypeTable.enum_variant_payload_count(tt, eid, 0) == 0)
    assert(TypeTable.enum_variant_payload_count(tt, eid, 1) == 1)
    assert(TypeTable.enum_variant_payload_type(tt, eid, 1, 0) == TYPE_I32())

fn test_array_type:
    var tt = TypeTable.new()
    let aid = TypeTable.add_array(tt, TYPE_I32(), 10)
    assert(TypeTable.is_array(tt, aid))
    assert(TypeTable.array_elem_type(tt, aid) == TYPE_I32())
    assert(TypeTable.array_size(tt, aid) == 10)

fn test_slice_type:
    var tt = TypeTable.new()
    let sid = TypeTable.add_slice(tt, TYPE_U8())
    assert(TypeTable.is_slice(tt, sid))
    assert(TypeTable.slice_elem_type(tt, sid) == TYPE_U8())

fn test_tuple_type:
    var tt = TypeTable.new()
    var elems = Vec.new()
    elems.push(TYPE_I32())
    elems.push(TYPE_BOOL())
    elems.push(TYPE_STR())
    let tid = TypeTable.add_tuple(tt, elems)
    assert(TypeTable.is_tuple(tt, tid))
    assert(TypeTable.tuple_elem_count(tt, tid) == 3)
    assert(TypeTable.tuple_elem_type(tt, tid, 0) == TYPE_I32())
    assert(TypeTable.tuple_elem_type(tt, tid, 1) == TYPE_BOOL())
    assert(TypeTable.tuple_elem_type(tt, tid, 2) == TYPE_STR())

fn test_fn_type:
    var tt = TypeTable.new()
    var params = Vec.new()
    params.push(TYPE_I32())
    params.push(TYPE_I32())
    let fid = TypeTable.add_fn(tt, params, TYPE_BOOL(), 0)
    assert(TypeTable.is_fn(tt, fid))
    assert(TypeTable.fn_param_count(tt, fid) == 2)
    assert(TypeTable.fn_return_type(tt, fid) == TYPE_BOOL())
    assert(TypeTable.fn_is_variadic(tt, fid) == 0)
    assert(TypeTable.fn_param_type(tt, fid, 0) == TYPE_I32())
    assert(TypeTable.fn_param_type(tt, fid, 1) == TYPE_I32())

fn test_ptr_ref_types:
    var tt = TypeTable.new()
    let pid = TypeTable.add_ptr(tt, TYPE_I32(), 0)
    assert(TypeTable.is_ptr(tt, pid))
    assert(TypeTable.pointee_type(tt, pid) == TYPE_I32())
    assert(not TypeTable.is_mut_ptr(tt, pid))
    assert(TypeTable.is_copy(tt, pid))

    let mid = TypeTable.add_ptr(tt, TYPE_I32(), 1)
    assert(TypeTable.is_mut_ptr(tt, mid))

    let rid = TypeTable.add_ref(tt, TYPE_STR(), 1)
    assert(TypeTable.is_ref(tt, rid))
    assert(TypeTable.pointee_type(tt, rid) == TYPE_STR())
    assert(TypeTable.is_mut_ref(tt, rid))

fn test_alias_type:
    var tt = TypeTable.new()
    let aid = TypeTable.add_alias(tt, 500, TYPE_I32())
    assert(TypeTable.is_alias(tt, aid))
    assert(TypeTable.alias_target(tt, aid) == TYPE_I32())
    assert(TypeTable.resolve_alias(tt, aid) == TYPE_I32())
    // Chain of aliases
    let aid2 = TypeTable.add_alias(tt, 501, aid)
    assert(TypeTable.resolve_alias(tt, aid2) == TYPE_I32())

fn test_option_result:
    var tt = TypeTable.new()
    let oid = TypeTable.add_option(tt, TYPE_I32())
    assert(TypeTable.is_option(tt, oid))
    assert(TypeTable.option_payload(tt, oid) == TYPE_I32())

    let rid = TypeTable.add_result(tt, TYPE_STR(), TYPE_I32())
    assert(TypeTable.is_result(tt, rid))
    assert(TypeTable.result_ok_type(tt, rid) == TYPE_STR())
    assert(TypeTable.result_err_type(tt, rid) == TYPE_I32())

fn test_type_equality:
    var tt = TypeTable.new()
    // Same builtin type
    assert(TypeTable.types_equal(tt, TYPE_I32(), TYPE_I32()))
    assert(not TypeTable.types_equal(tt, TYPE_I32(), TYPE_I64()))
    // Array types
    let a1 = TypeTable.add_array(tt, TYPE_I32(), 10)
    let a2 = TypeTable.add_array(tt, TYPE_I32(), 10)
    let a3 = TypeTable.add_array(tt, TYPE_I32(), 20)
    assert(TypeTable.types_equal(tt, a1, a2))
    assert(not TypeTable.types_equal(tt, a1, a3))
    // Option types
    let o1 = TypeTable.add_option(tt, TYPE_I32())
    let o2 = TypeTable.add_option(tt, TYPE_I32())
    let o3 = TypeTable.add_option(tt, TYPE_STR())
    assert(TypeTable.types_equal(tt, o1, o2))
    assert(not TypeTable.types_equal(tt, o1, o3))

fn test_generic_param:
    var tt = TypeTable.new()
    let gp = TypeTable.add_generic_param(tt, 600)
    assert(TypeTable.is_generic_param(tt, gp))
    assert(TypeTable.generic_param_name(tt, gp) == 600)

fn test_trait_obj:
    var tt = TypeTable.new()
    let to = TypeTable.add_trait_obj(tt, 700)
    assert(TypeTable.is_trait_obj(tt, to))
    assert(TypeTable.trait_obj_name(tt, to) == 700)

fn test_register_name:
    var tt = TypeTable.new()
    var names = Vec.new()
    var types = Vec.new()
    var defs = Vec.new()
    let sid = TypeTable.add_struct(tt, 800, names, types, defs)
    TypeTable.register_name(tt, "Point", sid)
    assert(TypeTable.lookup(tt, "Point") == sid)

fn test_var_info:
    var v = VarInfo.new(10, TYPE_I32(), 1)
    assert(v.name == 10)
    assert(v.type_id == TYPE_I32())
    assert(v.is_mutable == 1)
    assert(v.state == VS_LIVE())

fn test_scope:
    var s = Scope.new(-1)
    assert(s.parent_idx == -1)
    s.vars.insert("x", 0)
    let result = s.vars.get("x")
    assert(result.is_some())
    assert(result.unwrap() == 0)

fn main:
    test_builtins()
    test_named_lookup()
    test_predicates()
    test_struct_type()
    test_enum_type()
    test_array_type()
    test_slice_type()
    test_tuple_type()
    test_fn_type()
    test_ptr_ref_types()
    test_alias_type()
    test_option_result()
    test_type_equality()
    test_generic_param()
    test_trait_obj()
    test_register_name()
    test_var_info()
    test_scope()
    println("ok")
