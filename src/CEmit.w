// CEmit — C backend code emitter for the With compiler.
//
// Walks the AST (after parsing) and emits equivalent C source code.
// The emitted C links against runtime/with_runtime.c and runtime/helpers.c.
//
// Design:
//   - Single translation unit (all modules concatenated)
//   - Structs passed by pointer for method self params
//   - Vec/HashMap/Option mapped to runtime types
//   - Method name mangling: Type.method → Type_method
//   - No GC needed (compiler runs once and exits)

use Ast
use Type
use Token

// ── CEmit state ────────────────────────────────────────────────────

type CEmit = {
    pool: AstPool,
    source: str,
    out: str,
    sb: i64,
    indent_level: i32,
    tmp_counter: i32,

    // Known struct type names (for pass-by-pointer detection)
    struct_names: Vec[str],

    // Field info: parallel arrays mapping "Struct.field" → element type
    field_keys: Vec[str],
    field_elem_types: Vec[str],

    // Current method context
    current_struct_name: str,

    // Variable type tracking: parallel arrays name → c_type
    var_names: Vec[str],
    var_types: Vec[str],
    var_depth: Vec[i32],
    scope_depth: i32,
}

fn CEmit.new(pool: AstPool, source: str) -> CEmit:
    CEmit {
        pool: pool,
        source: source,
        out: "",
        sb: with_sb_new(),
        indent_level: 0,
        tmp_counter: 0,
        struct_names: Vec.new(),
        field_keys: Vec.new(),
        field_elem_types: Vec.new(),
        current_struct_name: "",
        var_names: Vec.new(),
        var_types: Vec.new(),
        var_depth: Vec.new(),
        scope_depth: 0,
    }

// ── Output helpers ─────────────────────────────────────────────────

fn CEmit.w(self: *mut CEmit, s: str) -> void:
    with_sb_append(self.sb, s)

fn CEmit.wl(self: *mut CEmit, s: str) -> void:
    CEmit.w_indent(self)
    with_sb_append(self.sb, s)
    with_sb_append(self.sb, "\n")

fn CEmit.nl(self: *mut CEmit) -> void:
    with_sb_append(self.sb, "\n")

fn CEmit.w_indent(self: *mut CEmit) -> void:
    var i = 0
    while i < self.indent_level:
        with_sb_append(self.sb, "    ")
        i = i + 1

fn CEmit.indent(self: *mut CEmit) -> void:
    self.indent_level = self.indent_level + 1

fn CEmit.dedent(self: *mut CEmit) -> void:
    if self.indent_level > 0:
        self.indent_level = self.indent_level - 1

fn CEmit.fresh_tmp(self: *mut CEmit) -> str:
    let n = self.tmp_counter
    self.tmp_counter = self.tmp_counter + 1
    "__t" ++ i32_to_str(n)

// ── Variable tracking ──────────────────────────────────────────────

fn CEmit.push_scope(self: *mut CEmit) -> void:
    self.scope_depth = self.scope_depth + 1

fn CEmit.pop_scope(self: *mut CEmit) -> void:
    // Remove variables at current scope depth
    var i = (self.var_names.len() as i32) - 1
    while i >= 0:
        if self.var_depth.get(i as i64) == self.scope_depth:
            // pop last entry (only works if i is last)
            0
        i = i - 1
    self.scope_depth = self.scope_depth - 1

fn CEmit.track_var(self: *mut CEmit, name: str, c_type: str) -> void:
    self.var_names.push(name)
    self.var_types.push(c_type)
    self.var_depth.push(self.scope_depth)

fn CEmit.lookup_var_type(self: *mut CEmit, name: str) -> str:
    var i = (self.var_names.len() as i32) - 1
    while i >= 0:
        if self.var_names.get(i as i64) == name:
            return self.var_types.get(i as i64)
        i = i - 1
    ""

// ── Field info lookup ──────────────────────────────────────────────

fn CEmit.record_field(self: *mut CEmit, key: str, elem_type: str) -> void:
    self.field_keys.push(key)
    self.field_elem_types.push(elem_type)

fn CEmit.lookup_field_elem(self: *mut CEmit, key: str) -> str:
    var i = 0
    let count = self.field_keys.len() as i32
    while i < count:
        if self.field_keys.get(i as i64) == key:
            return self.field_elem_types.get(i as i64)
        i = i + 1
    ""

fn CEmit.is_struct_name(self: *mut CEmit, name: str) -> bool:
    var i = 0
    let count = self.struct_names.len() as i32
    while i < count:
        if self.struct_names.get(i as i64) == name:
            return true
        i = i + 1
    false

// Returns the by-value struct dependency symbol for this type node, or -1.
// Pointer/reference/generic wrapper types do not require a complete struct definition.
fn CEmit.by_value_struct_dep(self: *mut CEmit, node: i32) -> i32:
    if node == 0:
        return -1
    let kind = AstPool.kind(self.pool, node)
    if kind == NK_TYPE_NAMED():
        let name_sym = AstPool.get_data0(self.pool, node)
        let name = AstPool.get_string(self.pool, name_sym)
        if CEmit.is_struct_name(self, name):
            return name_sym
        return -1
    if kind == NK_TYPE_PTR():
        return -1
    if kind == NK_TYPE_REF():
        return -1
    if kind == NK_TYPE_OPTIONAL():
        return -1
    if kind == NK_TYPE_GENERIC():
        return -1
    if kind == NK_TYPE_ARRAY():
        let elem = AstPool.get_data1(self.pool, node)
        return CEmit.by_value_struct_dep(self, elem)
    -1

// ── Type mapping ───────────────────────────────────────────────────

// Map an AST type node to a C type string.
fn CEmit.type_node_to_c(self: *mut CEmit, node: i32) -> str:
    if node == 0:
        return "void"
    let kind = AstPool.kind(self.pool, node)
    if kind == NK_TYPE_NAMED():
        let name = AstPool.get_string(self.pool, AstPool.get_data0(self.pool, node))
        return CEmit.type_name_to_c(self, name)
    if kind == NK_TYPE_GENERIC():
        let name = AstPool.get_string(self.pool, AstPool.get_data0(self.pool, node))
        if name == "Vec":
            return "with_vec"
        if name == "HashMap":
            return "void*"
        if name == "Option":
            // Get the payload type
            let extra_start = AstPool.get_data1(self.pool, node)
            let count = AstPool.get_data2(self.pool, node)
            if count > 0:
                let payload_node = AstPool.get_extra(self.pool, extra_start)
                let payload_c = CEmit.type_node_to_c(self, payload_node)
                if payload_c == "int32_t":
                    return "with_option_i32"
                if payload_c == "int64_t":
                    return "with_option_i64"
                if payload_c == "with_str":
                    return "with_option_str"
            return "with_option_i32"
        return name
    if kind == NK_TYPE_OPTIONAL():
        let inner = AstPool.get_data0(self.pool, node)
        let inner_c = CEmit.type_node_to_c(self, inner)
        if inner_c == "int32_t":
            return "with_option_i32"
        if inner_c == "int64_t":
            return "with_option_i64"
        if inner_c == "with_str":
            return "with_option_str"
        return "with_option_i32"
    if kind == NK_TYPE_REF():
        let inner = AstPool.get_data0(self.pool, node)
        return CEmit.type_node_to_c(self, inner) ++ "*"
    if kind == NK_TYPE_PTR():
        let inner = AstPool.get_data0(self.pool, node)
        return CEmit.type_node_to_c(self, inner) ++ "*"
    if kind == NK_TYPE_INFERRED():
        return "int32_t"
    "int32_t"

// Map a With type name to a C type string.
fn CEmit.type_name_to_c(self: *mut CEmit, name: str) -> str:
    if name == "i32" then "int32_t"
    else if name == "i64" then "int64_t"
    else if name == "i8" then "int8_t"
    else if name == "i16" then "int16_t"
    else if name == "u8" then "uint8_t"
    else if name == "u16" then "uint16_t"
    else if name == "u32" then "uint32_t"
    else if name == "u64" then "uint64_t"
    else if name == "f32" then "float"
    else if name == "f64" then "double"
    else if name == "bool" then "bool"
    else if name == "str" then "with_str"
    else if name == "void" then "void"
    else name

// Get the C sizeof expression for a type node (used for Vec.new element size).
fn CEmit.type_node_sizeof(self: *mut CEmit, node: i32) -> str:
    if node == 0:
        return "sizeof(int32_t)"
    let kind = AstPool.kind(self.pool, node)
    if kind == NK_TYPE_NAMED():
        let name = AstPool.get_string(self.pool, AstPool.get_data0(self.pool, node))
        let c = CEmit.type_name_to_c(self, name)
        return "sizeof(" ++ c ++ ")"
    if kind == NK_TYPE_GENERIC():
        let name = AstPool.get_string(self.pool, AstPool.get_data0(self.pool, node))
        if name == "Vec":
            return "sizeof(with_vec)"
        if name == "HashMap":
            return "sizeof(void*)"
        if name == "Option":
            return "sizeof(with_option_i32)"
        return "sizeof(" ++ name ++ ")"
    "sizeof(int32_t)"

// Get the Vec element type C string from a Vec[T] type node.
fn CEmit.vec_elem_c_type(self: *mut CEmit, node: i32) -> str:
    if node == 0:
        return "int32_t"
    let kind = AstPool.kind(self.pool, node)
    if kind == NK_TYPE_GENERIC():
        let name = AstPool.get_string(self.pool, AstPool.get_data0(self.pool, node))
        if name == "Vec":
            let extra_start = AstPool.get_data1(self.pool, node)
            let count = AstPool.get_data2(self.pool, node)
            if count > 0:
                let arg = AstPool.get_extra(self.pool, extra_start)
                return CEmit.type_node_to_c(self, arg)
    "int32_t"

// Mangle a function name: "Type.method" → "Type_method"
fn mangle(name: str) -> str:
    var result = ""
    var i = 0
    let len = name.len()
    while i < len:
        let ch = name[i]
        if ch == 46:
            result = result ++ "_"
        if ch != 46:
            result = result ++ char_to_str(ch)
        i = i + 1
    result

fn char_to_str(ch: i32) -> str:
    if ch == 95 then "_"
    else if ch >= 97 and ch <= 122 then str_from_byte(ch)
    else if ch >= 65 and ch <= 90 then str_from_byte(ch)
    else if ch >= 48 and ch <= 57 then str_from_byte(ch)
    else "_"

fn lbrace() -> str:
    str_from_byte(123)

fn rbrace() -> str:
    str_from_byte(125)

fn escape_c_string(s: str) -> str:
    var out = ""
    var i = 0
    let n = s.len() as i32
    while i < n:
        let ch = s[i]
        if ch == 92:
            out = out ++ "\\\\"
        else if ch == 34:
            out = out ++ "\\\""
        else if ch == 10:
            out = out ++ "\\n"
        else if ch == 13:
            out = out ++ "\\r"
        else if ch == 9:
            out = out ++ "\\t"
        else:
            out = out ++ str_from_byte(ch)
        i = i + 1
    out

extern fn str_from_byte(b: i32) -> str
extern fn i32_to_str(n: i32) -> str
extern fn with_sb_new() -> i64
extern fn with_sb_append(sb: i64, s: str) -> void
extern fn with_sb_build(sb: i64) -> str

// ── Module emission (top-level) ────────────────────────────────────

fn CEmit.emit_module(self: *mut CEmit) -> str:
    // Pass 1: collect struct names and field info
    CEmit.collect_types(self)

    // Pass 2: emit C code
    CEmit.emit_preamble(self)
    CEmit.emit_forward_structs(self)
    CEmit.emit_struct_defs(self)
    CEmit.emit_fn_forward_decls(self)
    CEmit.emit_fn_defs(self)
    CEmit.emit_main_wrapper(self)

    with_sb_build(self.sb)

// ── Pass 1: Collect type info ──────────────────────────────────────

fn CEmit.collect_types(self: *mut CEmit) -> void:
    let dc = AstPool.decl_count(self.pool)
    var i = 0
    while i < dc:
        let decl = AstPool.get_decl(self.pool, i)
        let kind = AstPool.kind(self.pool, decl)
        if kind == NK_TYPE_DECL():
            let name_str = AstPool.get_data0(self.pool, decl)
            let name = AstPool.get_string(self.pool, name_str)
            let flags = AstPool.get_data2(self.pool, decl)
            let tdk = (flags / 2) % 4
            if tdk == TDK_STRUCT():
                self.struct_names.push(name)
                // Record field types
                let extra_start = AstPool.get_data1(self.pool, decl)
                let field_count = flags / 256
                var fi = 0
                while fi < field_count:
                    let f_name_str = AstPool.get_extra(self.pool, extra_start + fi * 3)
                    let f_type_node = AstPool.get_extra(self.pool, extra_start + fi * 3 + 1)
                    let f_name = AstPool.get_string(self.pool, f_name_str)
                    let key = name ++ "." ++ f_name
                    // Check if field is Vec[T]
                    if f_type_node != 0:
                        let fk = AstPool.kind(self.pool, f_type_node)
                        if fk == NK_TYPE_GENERIC():
                            let gn = AstPool.get_string(self.pool, AstPool.get_data0(self.pool, f_type_node))
                            if gn == "Vec":
                                let elem = CEmit.vec_elem_c_type(self, f_type_node)
                                CEmit.record_field(self, key, elem)
                            if gn == "HashMap":
                                CEmit.record_field(self, key, "void*")
                    fi = fi + 1
        i = i + 1

// ── Preamble ───────────────────────────────────────────────────────

fn CEmit.emit_preamble(self: *mut CEmit) -> void:
    CEmit.w(self, "#include <stdint.h>\n")
    CEmit.w(self, "#include <stdbool.h>\n")
    CEmit.w(self, "#include <stdio.h>\n")
    CEmit.w(self, "#include <stdlib.h>\n")
    CEmit.w(self, "#include <string.h>\n")
    CEmit.w(self, "#include \"with_runtime.h\"\n\n")

    // Helper: str_from_byte
    CEmit.w(self, "static with_str str_from_byte(int32_t b) " ++ lbrace() ++ "\n")
    CEmit.w(self, "    char *buf = (char*)malloc(2);\n")
    CEmit.w(self, "    buf[0] = (char)b; buf[1] = 0;\n")
    CEmit.w(self, "    return (with_str)" ++ lbrace() ++ "buf, 1" ++ rbrace() ++ ";\n")
    CEmit.w(self, rbrace() ++ "\n\n")

    // Helper: i32_to_str
    CEmit.w(self, "static with_str i32_to_str(int32_t n) " ++ lbrace() ++ "\n")
    CEmit.w(self, "    return with_i32_to_str(n);\n")
    CEmit.w(self, rbrace() ++ "\n\n")

    // Helper: hashmap get returning option_i32
    CEmit.w(self, "static with_option_i32 __hm_get_str_i32(void *map, with_str key) " ++ lbrace() ++ "\n")
    CEmit.w(self, "    with_option_i32 r; int32_t v;\n")
    CEmit.w(self, "    r.has_value = (bool)with_hashmap_get(map, &key, &v, 1);\n")
    CEmit.w(self, "    r.value = v;\n")
    CEmit.w(self, "    return r;\n")
    CEmit.w(self, rbrace() ++ "\n\n")

    // Helper: hashmap insert str→i32
    CEmit.w(self, "static void __hm_insert_str_i32(void *map, with_str key, int32_t val) " ++ lbrace() ++ "\n")
    CEmit.w(self, "    with_hashmap_insert(map, &key, &val, 1);\n")
    CEmit.w(self, rbrace() ++ "\n\n")

    // Helper: hashmap contains str key
    CEmit.w(self, "static bool __hm_contains_str(void *map, with_str key) " ++ lbrace() ++ "\n")
    CEmit.w(self, "    return (bool)with_hashmap_contains(map, &key, 1);\n")
    CEmit.w(self, rbrace() ++ "\n\n")

    // Helper: println with string interpolation support
    CEmit.w(self, "static void with_println_fmt(with_str s) " ++ lbrace() ++ " with_println_str(s); " ++ rbrace() ++ "\n\n")

// ── Forward struct declarations ────────────────────────────────────

fn CEmit.emit_forward_structs(self: *mut CEmit) -> void:
    var i = 0
    let count = self.struct_names.len() as i32
    while i < count:
        let name = self.struct_names.get(i as i64)
        CEmit.w(self, "typedef struct " ++ name ++ " " ++ name ++ ";\n")
        i = i + 1
    CEmit.nl(self)

// ── Struct definitions ─────────────────────────────────────────────

fn CEmit.emit_struct_defs(self: *mut CEmit) -> void:
    let dc = AstPool.decl_count(self.pool)
    var struct_total = 0
    var driver_decl = -1
    var c = 0
    while c < dc:
        let decl = AstPool.get_decl(self.pool, c)
        let kind = AstPool.kind(self.pool, decl)
        if kind == NK_TYPE_DECL():
            let flags = AstPool.get_data2(self.pool, decl)
            let tdk = (flags / 2) % 4
            if tdk == TDK_STRUCT():
                let name_sym = AstPool.get_data0(self.pool, decl)
                let name = AstPool.get_string(self.pool, name_sym)
                if name == "Driver":
                    driver_decl = decl
                else:
                    struct_total = struct_total + 1
        c = c + 1

    var emitted = Vec.new()
    while (emitted.len() as i32) < struct_total:
        var progressed = 0
        var i = 0
        while i < dc:
            let decl = AstPool.get_decl(self.pool, i)
            let kind = AstPool.kind(self.pool, decl)
            if kind == NK_TYPE_DECL():
                let flags = AstPool.get_data2(self.pool, decl)
                let tdk = (flags / 2) % 4
                if tdk != TDK_STRUCT():
                    i = i + 1
                    continue
                let name_str = AstPool.get_data0(self.pool, decl)
                let name = AstPool.get_string(self.pool, name_str)
                if name == "Driver":
                    i = i + 1
                    continue
                // Skip already-emitted structs.
                var already = 0
                var ei = 0
                while ei < emitted.len() as i32:
                    if emitted.get(ei as i64) == name_str:
                        already = 1
                        break
                    ei = ei + 1

                if already == 0:
                    // Check whether all by-value struct field dependencies are emitted.
                    var ready = 1
                    let extra_start = AstPool.get_data1(self.pool, decl)
                    let field_count = flags / 256
                    var fi = 0
                    while fi < field_count:
                        let f_type_node = AstPool.get_extra(self.pool, extra_start + fi * 3 + 1)
                        let dep = CEmit.by_value_struct_dep(self, f_type_node)
                        if dep != -1 and dep != name_str:
                            var dep_ok = 0
                            var dj = 0
                            while dj < emitted.len() as i32:
                                if emitted.get(dj as i64) == dep:
                                    dep_ok = 1
                                    break
                                dj = dj + 1
                            if dep_ok == 0:
                                ready = 0
                                break
                        fi = fi + 1

                    if ready == 1:
                        CEmit.emit_type_decl(self, decl)
                        emitted.push(name_str)
                        progressed = 1
            i = i + 1

        if progressed == 1:
            continue

        // Fallback for cycles: emit any remaining structs to avoid infinite loop.
        var j = 0
        while j < dc:
            let decl = AstPool.get_decl(self.pool, j)
            let kind = AstPool.kind(self.pool, decl)
            if kind == NK_TYPE_DECL():
                let flags = AstPool.get_data2(self.pool, decl)
                let tdk = (flags / 2) % 4
                if tdk == TDK_STRUCT():
                    let name_str = AstPool.get_data0(self.pool, decl)
                    let name = AstPool.get_string(self.pool, name_str)
                    if name == "Driver":
                        j = j + 1
                        continue
                    var already = 0
                    var ei = 0
                    while ei < emitted.len() as i32:
                        if emitted.get(ei as i64) == name_str:
                            already = 1
                            break
                        ei = ei + 1
                    if already == 0:
                        CEmit.emit_type_decl(self, decl)
                        emitted.push(name_str)
            j = j + 1
        break

    // Emit Driver last (it holds other compiler structs by value).
    if driver_decl != -1:
        CEmit.emit_type_decl(self, driver_decl)
    CEmit.nl(self)

fn CEmit.emit_type_decl(self: *mut CEmit, node: i32) -> void:
    let name_str = AstPool.get_data0(self.pool, node)
    let name = AstPool.get_string(self.pool, name_str)
    let flags = AstPool.get_data2(self.pool, node)
    let tdk = (flags / 2) % 4
    if tdk != TDK_STRUCT():
        // Skip non-struct type decls for now (enums, aliases)
        return
    let extra_start = AstPool.get_data1(self.pool, node)
    let field_count = flags / 256

    CEmit.w(self, "struct " ++ name ++ " " ++ lbrace() ++ "\n")
    var fi = 0
    while fi < field_count:
        let f_name_str = AstPool.get_extra(self.pool, extra_start + fi * 3)
        let f_type_node = AstPool.get_extra(self.pool, extra_start + fi * 3 + 1)
        let f_name = AstPool.get_string(self.pool, f_name_str)
        var c_type = CEmit.type_node_to_c(self, f_type_node)
        if c_type.len() > 200:
            c_type = "int32_t"
        CEmit.w(self, "    " ++ c_type ++ " " ++ f_name ++ ";\n")
        fi = fi + 1
    CEmit.w(self, rbrace() ++ ";\n\n")

// ── Function forward declarations ──────────────────────────────────

fn CEmit.emit_fn_forward_decls(self: *mut CEmit) -> void:
    let dc = AstPool.decl_count(self.pool)
    var i = 0
    while i < dc:
        let decl = AstPool.get_decl(self.pool, i)
        let kind = AstPool.kind(self.pool, decl)
        if kind == NK_FN_DECL():
            CEmit.emit_fn_signature(self, decl, true)
            CEmit.w(self, ";\n")
        if kind == NK_EXTERN_FN():
            CEmit.emit_extern_fn(self, decl)
        i = i + 1
    CEmit.nl(self)

fn CEmit.emit_fn_signature(self: *mut CEmit, node: i32, is_forward: bool) -> void:
    let name_str = AstPool.get_data0(self.pool, node)
    let name = AstPool.get_string(self.pool, name_str)
    let extra_start = AstPool.get_data2(self.pool, node)

    let param_count = AstPool.get_extra(self.pool, extra_start)
    let flags = AstPool.get_extra(self.pool, extra_start + 1)
    let ret_type_node = AstPool.get_extra(self.pool, extra_start + 2)

    let ret_c = CEmit.type_node_to_c(self, ret_type_node)
    let mangled = mangle(name)

    // Rename "main" to avoid conflict with C main
    var fn_name = mangled
    if mangled == "main":
        fn_name = "with_main"

    CEmit.w(self, ret_c ++ " " ++ fn_name ++ "(")

    if param_count == 0:
        CEmit.w(self, "void")
    var pi = 0
    while pi < param_count:
        if pi > 0:
            CEmit.w(self, ", ")
        let p_name_str = AstPool.get_extra(self.pool, extra_start + 3 + pi * 2)
        let p_type_node = AstPool.get_extra(self.pool, extra_start + 3 + pi * 2 + 1)
        let p_name = AstPool.get_string(self.pool, p_name_str)
        let p_c_type = CEmit.type_node_to_c(self, p_type_node)

        // Check if this is a self parameter for a method (struct type → pointer)
        var actual_type = p_c_type
        if p_name == "self":
            if CEmit.is_struct_name(self, p_c_type):
                actual_type = p_c_type ++ "*"

        CEmit.w(self, actual_type ++ " " ++ p_name)
        pi = pi + 1
    CEmit.w(self, ")")

fn CEmit.emit_extern_fn(self: *mut CEmit, node: i32) -> void:
    let name_str = AstPool.get_data0(self.pool, node)
    let name = AstPool.get_string(self.pool, name_str)
    let extra_start = AstPool.get_data1(self.pool, node)

    // Skip runtime functions that are already declared in with_runtime.h
    if name == "str_from_byte":
        return
    if name == "i32_to_str":
        return

    let param_count = AstPool.get_extra(self.pool, extra_start)
    let ret_type_node = AstPool.get_extra(self.pool, extra_start + 1)
    let ret_c = CEmit.type_node_to_c(self, ret_type_node)

    CEmit.w(self, "extern " ++ ret_c ++ " " ++ name ++ "(")
    if param_count == 0:
        CEmit.w(self, "void")
    var pi = 0
    while pi < param_count:
        if pi > 0:
            CEmit.w(self, ", ")
        let p_name_str = AstPool.get_extra(self.pool, extra_start + 2 + pi * 2)
        let p_type_node = AstPool.get_extra(self.pool, extra_start + 2 + pi * 2 + 1)
        let p_name = AstPool.get_string(self.pool, p_name_str)
        let p_c_type = CEmit.type_node_to_c(self, p_type_node)
        CEmit.w(self, p_c_type ++ " " ++ p_name)
        pi = pi + 1
    CEmit.w(self, ");\n")

// ── Function definitions ───────────────────────────────────────────

fn CEmit.emit_fn_defs(self: *mut CEmit) -> void:
    let dc = AstPool.decl_count(self.pool)
    var i = 0
    while i < dc:
        let decl = AstPool.get_decl(self.pool, i)
        let kind = AstPool.kind(self.pool, decl)
        if kind == NK_FN_DECL():
            CEmit.emit_fn_def(self, decl)
        i = i + 1

fn CEmit.emit_fn_def(self: *mut CEmit, node: i32) -> void:
    let name_str = AstPool.get_data0(self.pool, node)
    let name = AstPool.get_string(self.pool, name_str)
    let body = AstPool.get_data1(self.pool, node)
    let extra_start = AstPool.get_data2(self.pool, node)

    let param_count = AstPool.get_extra(self.pool, extra_start)
    let ret_type_node = AstPool.get_extra(self.pool, extra_start + 2)
    let ret_c = CEmit.type_node_to_c(self, ret_type_node)
    let has_return = ret_c != "void"

    // Set current struct context for method self access
    self.current_struct_name = ""
    // Check if this is a method (name contains '.')
    var dot_pos = -1
    var ci = 0
    let nlen = name.len()
    while ci < nlen:
        if name[ci] == 46:
            dot_pos = ci
            ci = nlen
        ci = ci + 1
    if dot_pos > 0:
        self.current_struct_name = name.slice(0, dot_pos as i64)

    // Emit signature
    CEmit.emit_fn_signature(self, node, false)
    CEmit.w(self, " " ++ lbrace() ++ "\n")
    CEmit.indent(self)
    CEmit.push_scope(self)

    // Register parameters as variables
    var pi = 0
    while pi < param_count:
        let p_name_str = AstPool.get_extra(self.pool, extra_start + 3 + pi * 2)
        let p_type_node = AstPool.get_extra(self.pool, extra_start + 3 + pi * 2 + 1)
        let p_name = AstPool.get_string(self.pool, p_name_str)
        let p_c_type = CEmit.type_node_to_c(self, p_type_node)
        if p_name == "self":
            CEmit.track_var(self, "self", p_c_type ++ "*")
        if p_name != "self":
            CEmit.track_var(self, p_name, p_c_type)
        pi = pi + 1

    // Emit body
    if body == 0:
        // No body
        0
    if body != 0:
        let bk = AstPool.kind(self.pool, body)
        if bk == NK_BLOCK():
            CEmit.emit_block_contents(self, body, has_return)
        if bk != NK_BLOCK():
            // Single-body form can still be a statement (while/if/for/return/etc).
            // NK_IF_EXPR with has_return=true should be an expression (e.g. keyword_lookup's
            // if/then/else chain) — emit as expr and wrap with return, not as a statement.
            let is_stmt = bk == NK_RETURN() or (bk == NK_IF_EXPR() and not has_return) or bk == NK_WHILE() or bk == NK_LOOP() or bk == NK_FOR() or bk == NK_BLOCK() or bk == NK_BREAK() or bk == NK_CONTINUE() or bk == NK_DEFER() or bk == NK_ASSIGN() or bk == NK_LET_BINDING()
            if is_stmt:
                CEmit.emit_stmt(self, body)
            if not is_stmt:
                let expr_c = CEmit.emit_expr(self, body)
                if has_return:
                    CEmit.wl(self, "return " ++ expr_c ++ ";")
                if not has_return:
                    CEmit.wl(self, expr_c ++ ";")

    CEmit.pop_scope(self)
    CEmit.dedent(self)
    CEmit.w(self, rbrace() ++ "\n\n")
    self.current_struct_name = ""

// ── Block emission ─────────────────────────────────────────────────

fn CEmit.emit_block_contents(self: *mut CEmit, node: i32, has_return: bool) -> void:
    let extra_start = AstPool.get_data0(self.pool, node)
    let stmt_count = AstPool.get_data1(self.pool, node)
    let tail = AstPool.get_data2(self.pool, node)

    var i = 0
    while i < stmt_count:
        let stmt_node = AstPool.get_extra(self.pool, extra_start + i)
        CEmit.emit_stmt(self, stmt_node)
        i = i + 1

    // Tail expression → return
    if tail != 0:
        let tk = AstPool.kind(self.pool, tail)
        let is_stmt = tk == NK_RETURN() or tk == NK_IF_EXPR() or tk == NK_WHILE() or tk == NK_LOOP() or tk == NK_FOR() or tk == NK_BLOCK() or tk == NK_BREAK() or tk == NK_CONTINUE() or tk == NK_DEFER() or tk == NK_ASSIGN() or tk == NK_LET_BINDING()
        if has_return:
            if is_stmt:
                CEmit.emit_stmt(self, tail)
            if not is_stmt:
                let expr_c = CEmit.emit_expr(self, tail)
                CEmit.wl(self, "return " ++ expr_c ++ ";")
        if not has_return:
            CEmit.emit_stmt(self, tail)

// ── Statement emission ─────────────────────────────────────────────

fn CEmit.emit_stmt(self: *mut CEmit, node: i32) -> void:
    if node == 0:
        return
    let kind = AstPool.kind(self.pool, node)

    if kind == NK_LET_BINDING():
        CEmit.emit_let_binding(self, node)
        return
    if kind == NK_ASSIGN():
        let target = AstPool.get_data0(self.pool, node)
        let value = AstPool.get_data1(self.pool, node)
        let target_c = CEmit.emit_expr(self, target)
        let value_c = CEmit.emit_expr(self, value)
        CEmit.wl(self, target_c ++ " = " ++ value_c ++ ";")
        return
    if kind == NK_RETURN():
        let value = AstPool.get_data0(self.pool, node)
        if value == 0:
            CEmit.wl(self, "return;")
            return
        let expr_c = CEmit.emit_expr(self, value)
        CEmit.wl(self, "return " ++ expr_c ++ ";")
        return
    if kind == NK_IF_EXPR():
        CEmit.emit_if_stmt(self, node)
        return
    if kind == NK_WHILE():
        CEmit.emit_while(self, node)
        return
    if kind == NK_LOOP():
        CEmit.emit_loop(self, node)
        return
    if kind == NK_FOR():
        CEmit.emit_for(self, node)
        return
    if kind == NK_BREAK():
        CEmit.wl(self, "break;")
        return
    if kind == NK_CONTINUE():
        CEmit.wl(self, "continue;")
        return
    if kind == NK_BLOCK():
        CEmit.wl(self, lbrace())
        CEmit.indent(self)
        CEmit.push_scope(self)
        CEmit.emit_block_contents(self, node, false)
        CEmit.pop_scope(self)
        CEmit.dedent(self)
        CEmit.wl(self, rbrace())
        return
    if kind == NK_DEFER():
        // Emit as comment for now (proper defer needs scope tracking)
        let inner = AstPool.get_data0(self.pool, node)
        let expr_c = CEmit.emit_expr(self, inner)
        CEmit.wl(self, "/* defer */ " ++ expr_c ++ ";")
        return
    // Expression statement
    let expr_c = CEmit.emit_expr(self, node)
    if expr_c != "":
        CEmit.wl(self, expr_c ++ ";")

// ── Let/var binding ────────────────────────────────────────────────

fn CEmit.emit_let_binding(self: *mut CEmit, node: i32) -> void:
    let name_str = AstPool.get_data0(self.pool, node)
    let init = AstPool.get_data1(self.pool, node)
    let type_or_flag = AstPool.get_data2(self.pool, node)
    var type_node = type_or_flag
    if type_node >= 0x40000000:
        type_node = type_node - 0x40000000
    let name = AstPool.get_string(self.pool, name_str)

    var c_type = ""
    if type_node != 0:
        c_type = CEmit.type_node_to_c(self, type_node)

    // If no explicit type, try to infer from init expression
    if c_type == "":
        if init != 0:
            c_type = CEmit.infer_expr_type(self, init)
    if c_type == "":
        c_type = "int32_t"

    CEmit.track_var(self, name, c_type)

    if init == 0:
        CEmit.wl(self, c_type ++ " " ++ name ++ ";")
        return

    let init_c = CEmit.emit_expr(self, init)
    CEmit.wl(self, c_type ++ " " ++ name ++ " = " ++ init_c ++ ";")

// ── If statement ───────────────────────────────────────────────────

fn CEmit.emit_if_stmt(self: *mut CEmit, node: i32) -> void:
    let cond = AstPool.get_data0(self.pool, node)
    let then_body = AstPool.get_data1(self.pool, node)
    let else_body = AstPool.get_data2(self.pool, node)
    if cond == node or then_body == node or else_body == node:
        CEmit.wl(self, "/* self-referential if skipped */")
        return

    let cond_c = CEmit.emit_expr(self, cond)
    CEmit.wl(self, "if (" ++ cond_c ++ ") " ++ lbrace())
    CEmit.indent(self)
    CEmit.push_scope(self)
    CEmit.emit_body(self, then_body)
    CEmit.pop_scope(self)
    CEmit.dedent(self)

    if else_body == 0:
        CEmit.wl(self, rbrace())
        return

    let else_kind = AstPool.kind(self.pool, else_body)
    if else_kind == NK_IF_EXPR():
        CEmit.w_indent(self)
        CEmit.w(self, rbrace() ++ " else ")
        // Recursively emit else-if (no indent on the if keyword)
        CEmit.emit_if_stmt_inline(self, else_body)
        return

    CEmit.wl(self, rbrace() ++ " else " ++ lbrace())
    CEmit.indent(self)
    CEmit.push_scope(self)
    CEmit.emit_body(self, else_body)
    CEmit.pop_scope(self)
    CEmit.dedent(self)
    CEmit.wl(self, rbrace())

fn CEmit.emit_if_stmt_inline(self: *mut CEmit, node: i32) -> void:
    let cond = AstPool.get_data0(self.pool, node)
    let then_body = AstPool.get_data1(self.pool, node)
    let else_body = AstPool.get_data2(self.pool, node)

    let cond_c = CEmit.emit_expr(self, cond)
    CEmit.w(self, "if (" ++ cond_c ++ ") " ++ lbrace() ++ "\n")
    CEmit.indent(self)
    CEmit.push_scope(self)
    CEmit.emit_body(self, then_body)
    CEmit.pop_scope(self)
    CEmit.dedent(self)

    if else_body == 0:
        CEmit.wl(self, rbrace())
        return

    let else_kind = AstPool.kind(self.pool, else_body)
    if else_kind == NK_IF_EXPR():
        CEmit.w_indent(self)
        CEmit.w(self, rbrace() ++ " else ")
        CEmit.emit_if_stmt_inline(self, else_body)
        return

    CEmit.wl(self, rbrace() ++ " else " ++ lbrace())
    CEmit.indent(self)
    CEmit.push_scope(self)
    CEmit.emit_body(self, else_body)
    CEmit.pop_scope(self)
    CEmit.dedent(self)
    CEmit.wl(self, rbrace())

fn CEmit.emit_body(self: *mut CEmit, node: i32) -> void:
    if node == 0:
        return
    let kind = AstPool.kind(self.pool, node)
    if kind == NK_BLOCK():
        CEmit.emit_block_contents(self, node, false)
        return
    // Single expression/statement
    CEmit.emit_stmt(self, node)

// ── While loop ─────────────────────────────────────────────────────

fn CEmit.emit_while(self: *mut CEmit, node: i32) -> void:
    let cond = AstPool.get_data0(self.pool, node)
    let body = AstPool.get_data1(self.pool, node)

    let cond_c = CEmit.emit_expr(self, cond)
    CEmit.wl(self, "while (" ++ cond_c ++ ") " ++ lbrace())
    CEmit.indent(self)
    CEmit.push_scope(self)
    CEmit.emit_body(self, body)
    CEmit.pop_scope(self)
    CEmit.dedent(self)
    CEmit.wl(self, rbrace())

// ── Loop ───────────────────────────────────────────────────────────

fn CEmit.emit_loop(self: *mut CEmit, node: i32) -> void:
    let body = AstPool.get_data0(self.pool, node)
    CEmit.wl(self, "while (1) " ++ lbrace())
    CEmit.indent(self)
    CEmit.push_scope(self)
    CEmit.emit_body(self, body)
    CEmit.pop_scope(self)
    CEmit.dedent(self)
    CEmit.wl(self, rbrace())

// ── For loop ───────────────────────────────────────────────────────

fn CEmit.emit_for(self: *mut CEmit, node: i32) -> void:
    let binding_str = AstPool.get_data0(self.pool, node)
    let iterable = AstPool.get_data1(self.pool, node)
    let body = AstPool.get_data2(self.pool, node)
    let binding = AstPool.get_string(self.pool, binding_str)
    let iter_c = CEmit.emit_expr(self, iterable)

    // Emit as a range-based for using a temp
    let tmp = CEmit.fresh_tmp(self)
    CEmit.wl(self, "for (int64_t " ++ tmp ++ " = 0; " ++ tmp ++ " < " ++ iter_c ++ ".len; " ++ tmp ++ "++) " ++ lbrace())
    CEmit.indent(self)
    CEmit.wl(self, "int32_t " ++ binding ++ " = " ++ tmp ++ ";")
    CEmit.push_scope(self)
    CEmit.emit_body(self, body)
    CEmit.pop_scope(self)
    CEmit.dedent(self)
    CEmit.wl(self, rbrace())

// ── Expression emission ────────────────────────────────────────────

fn CEmit.emit_expr(self: *mut CEmit, node: i32) -> str:
    if node == 0:
        return "0"
    let kind = AstPool.kind(self.pool, node)

    if kind == NK_INT_LIT():
        let str_idx = AstPool.get_data0(self.pool, node)
        return AstPool.get_string(self.pool, str_idx)

    if kind == NK_FLOAT_LIT():
        let str_idx = AstPool.get_data0(self.pool, node)
        return AstPool.get_string(self.pool, str_idx)

    if kind == NK_STRING_LIT():
        let str_idx = AstPool.get_data0(self.pool, node)
        // Raw source text already has C-compatible escapes (With and C share escape syntax)
        let text = AstPool.get_string(self.pool, str_idx)
        return "WITH_STR_LIT(\"" ++ text ++ "\")"

    if kind == NK_BOOL_LIT():
        let val = AstPool.get_data0(self.pool, node)
        return if val == 1 then "true" else "false"

    if kind == NK_IDENT():
        let str_idx = AstPool.get_data0(self.pool, node)
        let name = AstPool.get_string(self.pool, str_idx)
        // "self" stays as "self" (it's already a pointer)
        return name

    if kind == NK_BINARY():
        return CEmit.emit_binary(self, node)

    if kind == NK_UNARY():
        return CEmit.emit_unary(self, node)

    if kind == NK_CALL():
        return CEmit.emit_call(self, node)

    if kind == NK_FIELD_ACCESS():
        return CEmit.emit_field_access(self, node)

    if kind == NK_INDEX():
        return CEmit.emit_index(self, node)

    if kind == NK_IF_EXPR():
        return CEmit.emit_if_expr(self, node)

    if kind == NK_CAST():
        let expr = AstPool.get_data0(self.pool, node)
        let type_node = AstPool.get_data1(self.pool, node)
        let expr_c = CEmit.emit_expr(self, expr)
        let type_c = CEmit.type_node_to_c(self, type_node)
        return "(" ++ type_c ++ ")(" ++ expr_c ++ ")"

    if kind == NK_STRUCT_LIT():
        return CEmit.emit_struct_lit(self, node)

    if kind == NK_GROUPED():
        let inner = AstPool.get_data0(self.pool, node)
        let inner_c = CEmit.emit_expr(self, inner)
        return "(" ++ inner_c ++ ")"

    if kind == NK_BLOCK():
        return CEmit.emit_block_expr(self, node)

    if kind == NK_TUPLE():
        // Emit as a compound literal or just the first element
        let extra_start = AstPool.get_data0(self.pool, node)
        let count = AstPool.get_data1(self.pool, node)
        if count > 0:
            return CEmit.emit_expr(self, AstPool.get_extra(self.pool, extra_start))
        return "0"

    if kind == NK_ARRAY_LIT():
        // Emit as a compound literal
        let extra_start = AstPool.get_data0(self.pool, node)
        let count = AstPool.get_data1(self.pool, node)
        var result = lbrace()
        var i = 0
        while i < count:
            if i > 0:
                result = result ++ ", "
            result = result ++ CEmit.emit_expr(self, AstPool.get_extra(self.pool, extra_start + i))
            i = i + 1
        return result ++ rbrace()

    if kind == NK_RETURN():
        let value = AstPool.get_data0(self.pool, node)
        if value == 0:
            return "return"
        return "return " ++ CEmit.emit_expr(self, value)

    if kind == NK_LET_BINDING():
        // Let binding as expression (shouldn't happen normally)
        CEmit.emit_let_binding(self, node)
        return "0"

    if kind == NK_ASSIGN():
        let target = AstPool.get_data0(self.pool, node)
        let value = AstPool.get_data1(self.pool, node)
        return CEmit.emit_expr(self, target) ++ " = " ++ CEmit.emit_expr(self, value)

    if kind == NK_C_STRING_LIT():
        let str_idx = AstPool.get_data0(self.pool, node)
        // Raw source text already has C-compatible escapes
        let text = AstPool.get_string(self.pool, str_idx)
        return "\"" ++ text ++ "\""

    // Default: emit as 0 with a comment
    "0 /* unhandled node kind */"

// ── Binary expression ──────────────────────────────────────────────

fn CEmit.emit_binary(self: *mut CEmit, node: i32) -> str:
    let lhs = AstPool.get_data0(self.pool, node)
    let rhs = AstPool.get_data1(self.pool, node)
    let op = AstPool.get_data2(self.pool, node)

    let lhs_c = CEmit.emit_expr(self, lhs)
    let rhs_c = CEmit.emit_expr(self, rhs)

    // String concatenation
    if op == OP_CONCAT():
        return "with_str_concat(" ++ lhs_c ++ ", " ++ rhs_c ++ ")"

    // String equality (heuristic: if either side is a string literal or known str var)
    if op == OP_EQ():
        if CEmit.is_str_expr(self, lhs) or CEmit.is_str_expr(self, rhs):
            return "with_str_eq(" ++ lhs_c ++ ", " ++ rhs_c ++ ")"
    if op == OP_NEQ():
        if CEmit.is_str_expr(self, lhs) or CEmit.is_str_expr(self, rhs):
            return "!with_str_eq(" ++ lhs_c ++ ", " ++ rhs_c ++ ")"

    let op_str = CEmit.binop_to_c(self, op)
    "(" ++ lhs_c ++ " " ++ op_str ++ " " ++ rhs_c ++ ")"

fn CEmit.binop_to_c(self: *mut CEmit, op: i32) -> str:
    if op == OP_ADD() then "+"
    else if op == OP_SUB() then "-"
    else if op == OP_MUL() then "*"
    else if op == OP_DIV() then "/"
    else if op == OP_MOD() then "%"
    else if op == OP_EQ() then "=="
    else if op == OP_NEQ() then "!="
    else if op == OP_LT() then "<"
    else if op == OP_GT() then ">"
    else if op == OP_LTE() then "<="
    else if op == OP_GTE() then ">="
    else if op == OP_AND() then "&&"
    else if op == OP_OR() then "||"
    else if op == OP_BIT_AND() then "&"
    else if op == OP_BIT_OR() then "|"
    else if op == OP_BIT_XOR() then "^"
    else if op == OP_SHL() then "<<"
    else if op == OP_SHR() then ">>"
    else if op == OP_DEFAULT() then "/* ?? */"
    else "+"

// Check if an expression is a string type (heuristic).
fn CEmit.is_str_expr(self: *mut CEmit, node: i32) -> bool:
    if node == 0:
        return false
    let kind = AstPool.kind(self.pool, node)
    if kind == NK_STRING_LIT():
        return true
    if kind == NK_BINARY():
        let op = AstPool.get_data2(self.pool, node)
        if op == OP_CONCAT():
            return true
    if kind == NK_IDENT():
        let name = AstPool.get_string(self.pool, AstPool.get_data0(self.pool, node))
        let vt = CEmit.lookup_var_type(self, name)
        if vt == "with_str":
            return true
    if kind == NK_CALL():
        // Check if the call returns str (heuristic: function name contains "to_str" or "version")
        let callee = AstPool.get_data0(self.pool, node)
        let ck = AstPool.kind(self.pool, callee)
        if ck == NK_IDENT():
            let fn_name = AstPool.get_string(self.pool, AstPool.get_data0(self.pool, callee))
            if fn_name == "version":
                return true
    if kind == NK_FIELD_ACCESS():
        let field_str = AstPool.get_data1(self.pool, node)
        let field = AstPool.get_string(self.pool, field_str)
        if field == "source" or field == "source_path" or field == "source_text" or field == "name" or field == "text" or field == "current_struct_name":
            return true
    false

// ── Unary expression ───────────────────────────────────────────────

fn CEmit.emit_unary(self: *mut CEmit, node: i32) -> str:
    let operand = AstPool.get_data0(self.pool, node)
    let op = AstPool.get_data1(self.pool, node)
    let operand_c = CEmit.emit_expr(self, operand)

    if op == UOP_NEGATE():
        return "(-" ++ operand_c ++ ")"
    if op == UOP_NOT():
        return "(!" ++ operand_c ++ ")"
    if op == UOP_REF():
        return "(&" ++ operand_c ++ ")"
    if op == UOP_MUT_REF():
        return "(&" ++ operand_c ++ ")"
    if op == UOP_DEREF():
        return "(*" ++ operand_c ++ ")"
    operand_c

// ── Call expression ────────────────────────────────────────────────

fn CEmit.emit_call(self: *mut CEmit, node: i32) -> str:
    let callee = AstPool.get_data0(self.pool, node)
    let extra_start = AstPool.get_data1(self.pool, node)
    let arg_count = AstPool.get_data2(self.pool, node)

    let ck = AstPool.kind(self.pool, callee)

    // Check for method call: callee is field_access (object.method)
    if ck == NK_FIELD_ACCESS():
        return CEmit.emit_method_call(self, node)

    // Regular function call
    if ck == NK_IDENT():
        let fn_name = AstPool.get_string(self.pool, AstPool.get_data0(self.pool, callee))
        return CEmit.emit_fn_call(self, fn_name, extra_start, arg_count)

    // Fallback: emit callee as expression
    let callee_c = CEmit.emit_expr(self, callee)
    var result = callee_c ++ "("
    var i = 0
    while i < arg_count:
        if i > 0:
            result = result ++ ", "
        result = result ++ CEmit.emit_expr(self, AstPool.get_extra(self.pool, extra_start + i))
        i = i + 1
    result ++ ")"

fn CEmit.emit_fn_call(self: *mut CEmit, fn_name: str, extra_start: i32, arg_count: i32) -> str:
    // Built-in function dispatch
    if fn_name == "println":
        return CEmit.emit_println(self, extra_start, arg_count)
    if fn_name == "print":
        if arg_count > 0:
            let arg = CEmit.emit_expr(self, AstPool.get_extra(self.pool, extra_start))
            return "with_print_str(" ++ arg ++ ")"
        return "with_print_str(WITH_STR_LIT(\"\"))"
    if fn_name == "assert":
        if arg_count > 0:
            let arg = CEmit.emit_expr(self, AstPool.get_extra(self.pool, extra_start))
            return "with_assert(" ++ arg ++ ", \"assert\", __FILE__, __LINE__)"
        return "with_assert(false, \"assert\", __FILE__, __LINE__)"
    if fn_name == "exit":
        if arg_count > 0:
            let arg = CEmit.emit_expr(self, AstPool.get_extra(self.pool, extra_start))
            return "exit(" ++ arg ++ ")"
        return "exit(0)"

    // Check if it's a static method call (Type.method format)
    var is_static_method = false
    var dot_pos = -1
    var ci = 0
    let nlen = fn_name.len()
    while ci < nlen:
        if fn_name[ci] == 46:
            dot_pos = ci
            is_static_method = true
            ci = nlen
        ci = ci + 1

    if is_static_method:
        let type_name = fn_name.slice(0, dot_pos as i64)
        let method = fn_name.slice((dot_pos + 1) as i64, nlen as i64)
        return CEmit.emit_static_method_call(self, type_name, method, fn_name, extra_start, arg_count)

    // Regular function call
    var mangled = mangle(fn_name)
    if mangled == "main":
        mangled = "with_main"
    let takes_self = CEmit.static_method_takes_self(self, fn_name)
    var result = mangled ++ "("
    var i = 0
    while i < arg_count:
        if i > 0:
            result = result ++ ", "
        let arg_node = AstPool.get_extra(self.pool, extra_start + i)
        let arg_c = CEmit.emit_expr(self, arg_node)
        if i == 0 and takes_self:
            result = result ++ CEmit.maybe_addr_of_arg(self, arg_node, arg_c)
        if not (i == 0 and takes_self):
            result = result ++ arg_c
        i = i + 1
    result ++ ")"

fn type_name_from_mangled(name: str) -> str:
    var i = 0
    let len = name.len()
    while i < len:
        if name[i] == 95:
            return name.slice(0, i as i64)
        i = i + 1
    ""

// ── Static method call (Type.method(args)) ─────────────────────────

fn CEmit.static_method_takes_self(self: *mut CEmit, full_name: str) -> bool:
    let target_mangled = mangle(full_name)
    let dc = AstPool.decl_count(self.pool)
    var i = 0
    while i < dc:
        let decl = AstPool.get_decl(self.pool, i)
        if AstPool.kind(self.pool, decl) == NK_FN_DECL():
            let name = AstPool.get_string(self.pool, AstPool.get_data0(self.pool, decl))
            if name == full_name or mangle(name) == target_mangled:
                let extra_start = AstPool.get_data2(self.pool, decl)
                let param_count = AstPool.get_extra(self.pool, extra_start)
                if param_count <= 0:
                    return false
                let first_param_name = AstPool.get_string(self.pool, AstPool.get_extra(self.pool, extra_start + 3))
                return first_param_name == "self"
        i = i + 1
    false

fn CEmit.emit_static_method_call(self: *mut CEmit, type_name: str, method: str, full_name: str, extra_start: i32, arg_count: i32) -> str:
    // Vec static methods
    if type_name == "Vec":
        if method == "new":
            return "with_vec_new(sizeof(int32_t))"
        return mangle(full_name) ++ "(" ++ CEmit.emit_args(self, extra_start, arg_count) ++ ")"

    // HashMap static methods
    if type_name == "HashMap":
        if method == "new":
            return "with_hashmap_new(sizeof(with_str), sizeof(int32_t))"
        return mangle(full_name) ++ "(" ++ CEmit.emit_args(self, extra_start, arg_count) ++ ")"

    let mangled = mangle(full_name)
    var needs_self = CEmit.static_method_takes_self(self, full_name)
    if not needs_self and method != "new" and CEmit.is_struct_name(self, type_name):
        needs_self = true
    if not needs_self:
        return mangled ++ "(" ++ CEmit.emit_args(self, extra_start, arg_count) ++ ")"
    var result = mangled ++ "("
    var i = 0
    while i < arg_count:
        if i > 0:
            result = result ++ ", "
        let arg_node = AstPool.get_extra(self.pool, extra_start + i)
        let arg_c = CEmit.emit_expr(self, arg_node)
        if i == 0:
            result = result ++ CEmit.maybe_addr_of_arg(self, arg_node, arg_c)
        if i != 0:
            result = result ++ arg_c
        i = i + 1
    result ++ ")"

fn CEmit.maybe_addr_of_arg(self: *mut CEmit, arg_node: i32, expr: str) -> str:
    // Already pointer-like expression.
    if expr == "self":
        return "self"
    if expr.len() > 0:
        let first = expr[0]
        if first == 38 or first == 42:
            return expr

    // Explicit ref expressions are already pointers.
    let ak = AstPool.kind(self.pool, arg_node)
    if ak == NK_UNARY():
        let op = AstPool.get_data1(self.pool, arg_node)
        if op == UOP_REF() or op == UOP_MUT_REF():
            return expr

    // Pointer-typed identifiers should not be re-addressed.
    if ak == NK_IDENT():
        let name = AstPool.get_string(self.pool, AstPool.get_data0(self.pool, arg_node))
        let vt = CEmit.lookup_var_type(self, name)
        let vlen = vt.len() as i32
        if vlen > 0:
            if vt[vlen - 1] == 42:
                return expr

    "&" ++ expr

fn CEmit.emit_args(self: *mut CEmit, extra_start: i32, arg_count: i32) -> str:
    var result = ""
    var i = 0
    while i < arg_count:
        if i > 0:
            result = result ++ ", "
        result = result ++ CEmit.emit_expr(self, AstPool.get_extra(self.pool, extra_start + i))
        i = i + 1
    result

// ── Instance method call (obj.method(args)) ────────────────────────

fn CEmit.emit_method_call(self: *mut CEmit, node: i32) -> str:
    let callee = AstPool.get_data0(self.pool, node)
    let extra_start = AstPool.get_data1(self.pool, node)
    let arg_count = AstPool.get_data2(self.pool, node)

    // callee is NK_FIELD_ACCESS: d0=object, d1=field_str
    let object = AstPool.get_data0(self.pool, callee)
    let method_str = AstPool.get_data1(self.pool, callee)
    let method = AstPool.get_string(self.pool, method_str)

    let obj_c = CEmit.emit_expr(self, object)

    // Static method call: Type.method(args) where Type is a known struct name.
    let obj_kind = AstPool.kind(self.pool, object)
    if obj_kind == NK_IDENT():
        let obj_name = AstPool.get_string(self.pool, AstPool.get_data0(self.pool, object))
        if CEmit.is_struct_name(self, obj_name) or obj_name == "Vec" or obj_name == "HashMap":
            let full_name = obj_name ++ "." ++ method
            return CEmit.emit_static_method_call(self, obj_name, method, full_name, extra_start, arg_count)

    // Detect built-in method calls
    // Vec methods
    if method == "push":
        return CEmit.emit_vec_push(self, obj_c, object, extra_start, arg_count)
    if method == "get" and arg_count == 1:
        return CEmit.emit_vec_or_hm_get(self, obj_c, object, extra_start)
    if method == "len" and arg_count == 0:
        return CEmit.emit_len_call(self, obj_c, object)

    // HashMap methods
    if method == "insert":
        return CEmit.emit_hm_insert(self, obj_c, object, extra_start, arg_count)
    if method == "contains":
        if arg_count > 0:
            let key_c = CEmit.emit_expr(self, AstPool.get_extra(self.pool, extra_start))
            return "__hm_contains_str(" ++ obj_c ++ ", " ++ key_c ++ ")"
        return "__hm_contains_str(" ++ obj_c ++ ", WITH_STR_LIT(\"\"))"

    // Option methods
    if method == "is_some":
        return obj_c ++ ".has_value"
    if method == "unwrap":
        return obj_c ++ ".value"
    if method == "is_none":
        return "!" ++ obj_c ++ ".has_value"

    // String methods
    if method == "slice":
        if arg_count >= 2:
            let start_c = CEmit.emit_expr(self, AstPool.get_extra(self.pool, extra_start))
            let end_c = CEmit.emit_expr(self, AstPool.get_extra(self.pool, extra_start + 1))
            return "with_str_substr(" ++ obj_c ++ ", " ++ start_c ++ ", " ++ end_c ++ " - " ++ start_c ++ ")"
        return obj_c

    // Generic method call: assume it's a known method on a type
    // Try to figure out the type of the object for proper dispatch
    let obj_type = CEmit.infer_expr_type(self, object)
    if obj_type != "":
        if CEmit.is_struct_name(self, obj_type):
            // It's a struct method call: Type_method(&obj, args)
            let mangled = obj_type ++ "_" ++ method
            var result = mangled ++ "(&" ++ obj_c
            var i = 0
            while i < arg_count:
                result = result ++ ", "
                result = result ++ CEmit.emit_expr(self, AstPool.get_extra(self.pool, extra_start + i))
                i = i + 1
            return result ++ ")"

    // Fallback: emit as obj.method(args)
    var result = obj_c ++ "." ++ method ++ "("
    var i = 0
    while i < arg_count:
        if i > 0:
            result = result ++ ", "
        result = result ++ CEmit.emit_expr(self, AstPool.get_extra(self.pool, extra_start + i))
        i = i + 1
    result ++ ")"

// ── Vec push ───────────────────────────────────────────────────────

fn CEmit.emit_vec_push(self: *mut CEmit, obj_c: str, obj_node: i32, extra_start: i32, arg_count: i32) -> str:
    let elem_type = CEmit.infer_vec_elem_type(self, obj_node)
    if arg_count == 0:
        return "/* vec push no arg */"
    let val_c = CEmit.emit_expr(self, AstPool.get_extra(self.pool, extra_start))

    if elem_type == "int32_t" or elem_type == "i32":
        return "with_vec_push_i32(&" ++ obj_c ++ ", " ++ val_c ++ ")"
    if elem_type == "int64_t" or elem_type == "i64":
        return "with_vec_push_i64(&" ++ obj_c ++ ", " ++ val_c ++ ")"
    if elem_type == "with_str" or elem_type == "str":
        return "with_vec_push_str(&" ++ obj_c ++ ", " ++ val_c ++ ")"
    if elem_type == "bool":
        return "with_vec_push_bool(&" ++ obj_c ++ ", " ++ val_c ++ ")"
    // Generic: push by pointer
    "with_vec_push(&" ++ obj_c ++ ", &" ++ val_c ++ ")"

// ── Vec/HashMap get ────────────────────────────────────────────────

fn CEmit.emit_vec_or_hm_get(self: *mut CEmit, obj_c: str, obj_node: i32, extra_start: i32) -> str:
    let idx_c = CEmit.emit_expr(self, AstPool.get_extra(self.pool, extra_start))

    // Check if this is a HashMap get (returns Option)
    let obj_type = CEmit.infer_expr_type(self, obj_node)
    if obj_type == "void*":
        // HashMap get → returns Option
        return "__hm_get_str_i32(" ++ obj_c ++ ", " ++ idx_c ++ ")"

    let elem_type = CEmit.infer_vec_elem_type(self, obj_node)
    if elem_type == "int32_t" or elem_type == "i32":
        return "with_vec_get_i32(&" ++ obj_c ++ ", " ++ idx_c ++ ")"
    if elem_type == "int64_t" or elem_type == "i64":
        return "with_vec_get_i64(&" ++ obj_c ++ ", " ++ idx_c ++ ")"
    if elem_type == "with_str" or elem_type == "str":
        return "with_vec_get_str(&" ++ obj_c ++ ", " ++ idx_c ++ ")"
    if elem_type == "bool":
        return "with_vec_get_bool(&" ++ obj_c ++ ", " ++ idx_c ++ ")"
    // Generic: get by pointer and cast
    "*(" ++ elem_type ++ "*)with_vec_get_ptr(&" ++ obj_c ++ ", " ++ idx_c ++ ")"

// ── Vec/str len ────────────────────────────────────────────────────

fn CEmit.emit_len_call(self: *mut CEmit, obj_c: str, obj_node: i32) -> str:
    let obj_type = CEmit.infer_expr_type(self, obj_node)
    if obj_type == "with_str":
        return obj_c ++ ".len"
    if obj_type == "void*":
        return "with_hashmap_len(" ++ obj_c ++ ")"
    // Default: assume vec
    "with_vec_len(&" ++ obj_c ++ ")"

// ── HashMap insert ─────────────────────────────────────────────────

fn CEmit.emit_hm_insert(self: *mut CEmit, obj_c: str, obj_node: i32, extra_start: i32, arg_count: i32) -> str:
    if arg_count < 2:
        return "/* hm insert: not enough args */"
    let key_c = CEmit.emit_expr(self, AstPool.get_extra(self.pool, extra_start))
    let val_c = CEmit.emit_expr(self, AstPool.get_extra(self.pool, extra_start + 1))
    "__hm_insert_str_i32(" ++ obj_c ++ ", " ++ key_c ++ ", " ++ val_c ++ ")"

// ── Infer Vec element type from context ────────────────────────────

fn CEmit.infer_vec_elem_type(self: *mut CEmit, obj_node: i32) -> str:
    if obj_node == 0:
        return "int32_t"
    let kind = AstPool.kind(self.pool, obj_node)
    // If it's a field access on self, look up the field elem type
    if kind == NK_FIELD_ACCESS():
        let obj = AstPool.get_data0(self.pool, obj_node)
        let field_str = AstPool.get_data1(self.pool, obj_node)
        let field_name = AstPool.get_string(self.pool, field_str)
        let ok = AstPool.kind(self.pool, obj)
        if ok == NK_IDENT():
            let obj_name = AstPool.get_string(self.pool, AstPool.get_data0(self.pool, obj))
            if obj_name == "self":
                if self.current_struct_name != "":
                    let key = self.current_struct_name ++ "." ++ field_name
                    let elem = CEmit.lookup_field_elem(self, key)
                    if elem != "":
                        return elem
            // Look up variable type to find struct type
            let vt = CEmit.lookup_var_type(self, obj_name)
            // Try to find struct name from variable type
            var sname = vt
            if vt.len() > 0:
                // Remove trailing * if pointer
                let last = vt[vt.len() - 1]
                if last == 42:
                    sname = vt.slice(0, vt.len() - 1)
            if sname != "":
                let key = sname ++ "." ++ field_name
                let elem = CEmit.lookup_field_elem(self, key)
                if elem != "":
                    return elem
    // If it's a local variable, check its recorded type
    if kind == NK_IDENT():
        let var_name = AstPool.get_string(self.pool, AstPool.get_data0(self.pool, obj_node))
        let vt = CEmit.lookup_var_type(self, var_name)
        // Look for elem type by convention
        if vt == "with_vec":
            return "int32_t"
    "int32_t"

fn CEmit.lookup_fn_return_type(self: *mut CEmit, fn_name: str) -> str:
    let dc = AstPool.decl_count(self.pool)
    var i = 0
    while i < dc:
        let decl = AstPool.get_decl(self.pool, i)
        let kind = AstPool.kind(self.pool, decl)
        if kind == NK_FN_DECL():
            let name = AstPool.get_string(self.pool, AstPool.get_data0(self.pool, decl))
            if name == fn_name or mangle(name) == fn_name:
                let extra_start = AstPool.get_data2(self.pool, decl)
                let ret_type_node = AstPool.get_extra(self.pool, extra_start + 2)
                return CEmit.type_node_to_c(self, ret_type_node)
        if kind == NK_EXTERN_FN():
            let name = AstPool.get_string(self.pool, AstPool.get_data0(self.pool, decl))
            if name == fn_name:
                let extra_start = AstPool.get_data1(self.pool, decl)
                let ret_type_node = AstPool.get_extra(self.pool, extra_start + 1)
                return CEmit.type_node_to_c(self, ret_type_node)
        i = i + 1
    ""

// ── Infer expression type ──────────────────────────────────────────

fn CEmit.infer_expr_type(self: *mut CEmit, node: i32) -> str:
    if node == 0:
        return ""
    let kind = AstPool.kind(self.pool, node)
    if kind == NK_INT_LIT():
        return "int32_t"
    if kind == NK_STRING_LIT():
        return "with_str"
    if kind == NK_BOOL_LIT():
        return "bool"
    if kind == NK_IDENT():
        let name = AstPool.get_string(self.pool, AstPool.get_data0(self.pool, node))
        return CEmit.lookup_var_type(self, name)
    if kind == NK_FIELD_ACCESS():
        let obj = AstPool.get_data0(self.pool, node)
        let field_str = AstPool.get_data1(self.pool, node)
        let field_name = AstPool.get_string(self.pool, field_str)
        // Check if obj is self or a known struct-typed local.
        let ok = AstPool.kind(self.pool, obj)
        if ok == NK_IDENT():
            let obj_name = AstPool.get_string(self.pool, AstPool.get_data0(self.pool, obj))
            if obj_name == "self":
                if self.current_struct_name != "":
                    // Look up field type in struct definition
                    return CEmit.lookup_struct_field_type(self, self.current_struct_name, field_name)
            let vt = CEmit.lookup_var_type(self, obj_name)
            var sname = vt
            if vt.len() > 0:
                let last = vt[vt.len() - 1]
                if last == 42:
                    sname = vt.slice(0, vt.len() - 1)
            if sname != "" and CEmit.is_struct_name(self, sname):
                let ft = CEmit.lookup_struct_field_type(self, sname, field_name)
                if ft != "":
                    return ft
                let key = sname ++ "." ++ field_name
                let fte = CEmit.lookup_field_elem(self, key)
                if fte != "":
                    return fte
    if kind == NK_BINARY():
        let op = AstPool.get_data2(self.pool, node)
        if op == OP_CONCAT():
            return "with_str"
        if op == OP_EQ() or op == OP_NEQ() or op == OP_LT() or op == OP_GT() or op == OP_LTE() or op == OP_GTE() or op == OP_AND() or op == OP_OR():
            return "bool"
        return CEmit.infer_expr_type(self, AstPool.get_data0(self.pool, node))
    if kind == NK_CAST():
        let type_node = AstPool.get_data1(self.pool, node)
        return CEmit.type_node_to_c(self, type_node)
    if kind == NK_STRUCT_LIT():
        let type_str = AstPool.get_data0(self.pool, node)
        return AstPool.get_string(self.pool, type_str)
    if kind == NK_CALL():
        // Try to infer from function return type
        let callee = AstPool.get_data0(self.pool, node)
        let ck = AstPool.kind(self.pool, callee)
        if ck == NK_IDENT():
            let fn_name = AstPool.get_string(self.pool, AstPool.get_data0(self.pool, callee))
            if fn_name == "with_str_substr":
                return "with_str"
            let ret = CEmit.lookup_fn_return_type(self, fn_name)
            if ret != "":
                return ret
        if ck == NK_FIELD_ACCESS():
            let obj = AstPool.get_data0(self.pool, callee)
            let method_str = AstPool.get_data1(self.pool, callee)
            let method = AstPool.get_string(self.pool, method_str)
            if method == "len":
                return "int64_t"
            if method == "get":
                // Could be vec get or hashmap get
                let obj_type = CEmit.infer_expr_type(self, obj)
                if obj_type == "void*":
                    return "with_option_i32"
                let elem = CEmit.infer_vec_elem_type(self, obj)
                if elem != "":
                    return elem
                return "int32_t"
            if method == "is_some" or method == "is_none":
                return "bool"
            if method == "unwrap":
                return "int32_t"
            if method == "slice":
                return "with_str"
            if method == "new":
                let ok = AstPool.kind(self.pool, obj)
                if ok == NK_IDENT():
                    let obj_name = AstPool.get_string(self.pool, AstPool.get_data0(self.pool, obj))
                    if obj_name == "Vec":
                        return "with_vec"
                    if obj_name == "HashMap":
                        return "void*"
                    if CEmit.is_struct_name(self, obj_name):
                        return obj_name
            let ok = AstPool.kind(self.pool, obj)
            if ok == NK_IDENT():
                let obj_name = AstPool.get_string(self.pool, AstPool.get_data0(self.pool, obj))
                if CEmit.is_struct_name(self, obj_name):
                    let full_name = obj_name ++ "." ++ method
                    let ret = CEmit.lookup_fn_return_type(self, full_name)
                    if ret != "":
                        return ret
            let obj_type = CEmit.infer_expr_type(self, obj)
            if obj_type != "" and CEmit.is_struct_name(self, obj_type):
                let full_name = obj_type ++ "." ++ method
                let ret = CEmit.lookup_fn_return_type(self, full_name)
                if ret != "":
                    return ret
    ""

fn CEmit.lookup_struct_field_type(self: *mut CEmit, struct_name: str, field_name: str) -> str:
    // Look through declarations to find the struct and its field type
    let dc = AstPool.decl_count(self.pool)
    var i = 0
    while i < dc:
        let decl = AstPool.get_decl(self.pool, i)
        let kind = AstPool.kind(self.pool, decl)
        if kind == NK_TYPE_DECL():
            let ns = AstPool.get_data0(self.pool, decl)
            let n = AstPool.get_string(self.pool, ns)
            if n == struct_name:
                let flags = AstPool.get_data2(self.pool, decl)
                let tdk = (flags / 2) % 4
                if tdk == TDK_STRUCT():
                    let extra_start = AstPool.get_data1(self.pool, decl)
                    let field_count = flags / 256
                    var fi = 0
                    while fi < field_count:
                        let f_name_str = AstPool.get_extra(self.pool, extra_start + fi * 3)
                        let f_type_node = AstPool.get_extra(self.pool, extra_start + fi * 3 + 1)
                        let f_name = AstPool.get_string(self.pool, f_name_str)
                        if f_name == field_name:
                            return CEmit.type_node_to_c(self, f_type_node)
                        fi = fi + 1
        i = i + 1
    ""

// ── Field access ───────────────────────────────────────────────────

fn CEmit.emit_field_access(self: *mut CEmit, node: i32) -> str:
    let obj = AstPool.get_data0(self.pool, node)
    let field_str = AstPool.get_data1(self.pool, node)
    let field_name = AstPool.get_string(self.pool, field_str)
    let obj_c = CEmit.emit_expr(self, obj)

    // Determine if object is a pointer (struct self → use ->)
    let obj_type = CEmit.infer_expr_type(self, obj)
    if obj_type.len() > 0:
        let last = obj_type[obj_type.len() - 1]
        if last == 42:
            return obj_c ++ "->" ++ field_name

    // If obj is "self", it's always a pointer
    let ok = AstPool.kind(self.pool, obj)
    if ok == NK_IDENT():
        let obj_name = AstPool.get_string(self.pool, AstPool.get_data0(self.pool, obj))
        if obj_name == "self":
            return "self->" ++ field_name

    obj_c ++ "." ++ field_name

// ── Index expression ───────────────────────────────────────────────

fn CEmit.emit_index(self: *mut CEmit, node: i32) -> str:
    let obj = AstPool.get_data0(self.pool, node)
    let idx = AstPool.get_data1(self.pool, node)
    let obj_c = CEmit.emit_expr(self, obj)
    let idx_c = CEmit.emit_expr(self, idx)

    // Check if obj is a str → byte access
    let obj_type = CEmit.infer_expr_type(self, obj)
    if obj_type == "with_str":
        return "(int32_t)(uint8_t)" ++ obj_c ++ ".ptr[" ++ idx_c ++ "]"

    // Default: array-style indexing
    obj_c ++ "[" ++ idx_c ++ "]"

// ── If expression (ternary) ────────────────────────────────────────

fn CEmit.emit_if_expr(self: *mut CEmit, node: i32) -> str:
    let cond = AstPool.get_data0(self.pool, node)
    let then_body = AstPool.get_data1(self.pool, node)
    let else_body = AstPool.get_data2(self.pool, node)

    // Check if branches are simple expressions (not blocks)
    let then_kind = AstPool.kind(self.pool, then_body)
    let can_ternary = then_kind != NK_BLOCK() and else_body != 0

    if can_ternary:
        let cond_c = CEmit.emit_expr(self, cond)
        let then_c = CEmit.emit_expr(self, then_body)
        if else_body == 0:
            return "(" ++ cond_c ++ " ? " ++ then_c ++ " : 0)"
        let else_c = CEmit.emit_expr(self, else_body)
        return "(" ++ cond_c ++ " ? " ++ then_c ++ " : " ++ else_c ++ ")"

    // Complex if: use temp variable
    let tmp = CEmit.fresh_tmp(self)
    let result_type = CEmit.infer_expr_type(self, then_body)
    var c_type = result_type
    if c_type == "":
        c_type = "int32_t"

    CEmit.wl(self, c_type ++ " " ++ tmp ++ ";")
    let cond_c = CEmit.emit_expr(self, cond)
    CEmit.wl(self, "if (" ++ cond_c ++ ") " ++ lbrace())
    CEmit.indent(self)
    let then_c = CEmit.emit_expr(self, then_body)
    CEmit.wl(self, tmp ++ " = " ++ then_c ++ ";")
    CEmit.dedent(self)
    if else_body != 0:
        CEmit.wl(self, rbrace() ++ " else " ++ lbrace())
        CEmit.indent(self)
        let else_c = CEmit.emit_expr(self, else_body)
        CEmit.wl(self, tmp ++ " = " ++ else_c ++ ";")
        CEmit.dedent(self)
    CEmit.wl(self, rbrace())
    tmp

// ── Block as expression ────────────────────────────────────────────

fn CEmit.emit_block_expr(self: *mut CEmit, node: i32) -> str:
    let extra_start = AstPool.get_data0(self.pool, node)
    let stmt_count = AstPool.get_data1(self.pool, node)
    let tail = AstPool.get_data2(self.pool, node)

    // Emit statements
    var i = 0
    while i < stmt_count:
        let stmt_node = AstPool.get_extra(self.pool, extra_start + i)
        CEmit.emit_stmt(self, stmt_node)
        i = i + 1

    // Return tail expression
    if tail != 0:
        return CEmit.emit_expr(self, tail)
    "0"

// ── Struct literal ─────────────────────────────────────────────────

fn CEmit.emit_struct_lit(self: *mut CEmit, node: i32) -> str:
    let type_str = AstPool.get_data0(self.pool, node)
    let extra_start = AstPool.get_data1(self.pool, node)
    let field_count = AstPool.get_data2(self.pool, node)
    let type_name = AstPool.get_string(self.pool, type_str)

    var result = "(" ++ type_name ++ ")" ++ lbrace()
    var fi = 0
    while fi < field_count:
        if fi > 0:
            result = result ++ ", "
        let f_name_str = AstPool.get_extra(self.pool, extra_start + fi * 2)
        let f_val_node = AstPool.get_extra(self.pool, extra_start + fi * 2 + 1)
        let f_name = AstPool.get_string(self.pool, f_name_str)
        let f_val_c = CEmit.emit_struct_field_init(self, type_name, f_name, f_val_node)
        result = result ++ "." ++ f_name ++ " = " ++ f_val_c
        fi = fi + 1
    result ++ rbrace()

fn CEmit.emit_struct_field_init(self: *mut CEmit, struct_name: str, field_name: str, val_node: i32) -> str:
    // Check if this is a Vec.new() or HashMap.new() initializer
    if val_node == 0:
        return "0"
    let kind = AstPool.kind(self.pool, val_node)
    if kind == NK_CALL():
        let callee = AstPool.get_data0(self.pool, val_node)
        let ck = AstPool.kind(self.pool, callee)
        if ck == NK_FIELD_ACCESS():
            let obj = AstPool.get_data0(self.pool, callee)
            let method_str = AstPool.get_data1(self.pool, callee)
            let method = AstPool.get_string(self.pool, method_str)
            if method == "new":
                let obj_kind = AstPool.kind(self.pool, obj)
                if obj_kind == NK_IDENT():
                    let obj_name = AstPool.get_string(self.pool, AstPool.get_data0(self.pool, obj))
                    if obj_name == "Vec":
                        // Look up element type from struct field declaration
                        let key = struct_name ++ "." ++ field_name
                        let elem = CEmit.lookup_field_elem(self, key)
                        if elem != "":
                            return "with_vec_new(sizeof(" ++ elem ++ "))"
                        return "with_vec_new(sizeof(int32_t))"
                    if obj_name == "HashMap":
                        return "with_hashmap_new(sizeof(with_str), sizeof(int32_t))"
        if ck == NK_IDENT():
            let fn_name = AstPool.get_string(self.pool, AstPool.get_data0(self.pool, callee))
            // Check for static constructor calls like TraitSolver.new()
            var dot_pos = -1
            var ci = 0
            let fnlen = fn_name.len()
            while ci < fnlen:
                if fn_name[ci] == 46:
                    dot_pos = ci
                    ci = fnlen
                ci = ci + 1
            if dot_pos > 0:
                let tn = fn_name.slice(0, dot_pos as i64)
                let mn = fn_name.slice((dot_pos + 1) as i64, fnlen as i64)
                if mn == "new":
                    return mangle(fn_name) ++ "()"
    CEmit.emit_expr(self, val_node)

// ── Println ────────────────────────────────────────────────────────

fn CEmit.emit_println(self: *mut CEmit, extra_start: i32, arg_count: i32) -> str:
    if arg_count == 0:
        return "with_println_str(WITH_STR_LIT(\"\"))"
    let arg_node = AstPool.get_extra(self.pool, extra_start)
    let arg_c = CEmit.emit_expr(self, arg_node)
    let arg_type = CEmit.infer_expr_type(self, arg_node)

    if arg_type == "int32_t":
        return "with_println_i32(" ++ arg_c ++ ")"
    if arg_type == "int64_t":
        return "with_println_i64(" ++ arg_c ++ ")"
    if arg_type == "bool":
        return "with_println_bool(" ++ arg_c ++ ")"
    // Default: string
    "with_println_str(" ++ arg_c ++ ")"

// ── Main wrapper ───────────────────────────────────────────────────

fn CEmit.emit_main_wrapper(self: *mut CEmit) -> void:
    CEmit.w(self, "int main(int argc, char **argv) " ++ lbrace() ++ "\n")
    CEmit.w(self, "    with_main();\n")
    CEmit.w(self, "    return 0;\n")
    CEmit.w(self, rbrace() ++ "\n")
