// Parser — Recursive descent parser: tokens -> AST.
//
// Consumes a TokenList and produces nodes in an AstPool.
// On parse errors, emits a diagnostic and recovers to next top-level decl.

use Ast
use Token
use Span
use Lexer
use InternPool
use Diagnostic

extern fn int_to_string(n: i32) -> str
extern fn str_from_byte(b: i32) -> str
extern fn with_parse_i64(s: str) -> i64
type Parser = {
    tokens: TokenList,
    pos: i32,
    pool: AstPool,
    intern: InternPool,
    diags: DiagnosticList,
    source: str,
    file_id: i32,
    suppress_as: i32,
    pending_tailrec: i32,
    pending_inline: i32,
    pending_noinline: i32,
    pending_must_use: i32,
    pending_panic_handler: i32,
    pending_entry: i32,
    pending_no_main: i32,
    pending_test: i32,
    pending_before: i32,
    pending_after: i32,
    pending_derive_start: i32,
    pending_derive_count: i32,
    pending_sealed: i32,
    pending_flags: i32,
    saw_implicit_it: i32,
    implicit_it_depth: i32,
    last_param_pattern_start: i32,
    last_param_pattern_count: i32,
    last_param_required_count: i32,
    last_where_start: i32,
    last_where_count: i32,
}

fn Parser.init(tokens: TokenList, source: str, file_id: i32, intern: InternPool, diags: DiagnosticList) -> Parser:
    Parser.init_with_pool(tokens, source, file_id, intern, diags, AstPool.new())

fn Parser.init_with_pool(tokens: TokenList, source: str, file_id: i32, intern: InternPool, diags: DiagnosticList, pool: AstPool) -> Parser:
    Parser {
        tokens,
        pos: 0,
        pool,
        intern,
        diags,
        source,
        file_id,
        suppress_as: 0,
        pending_tailrec: 0,
        pending_inline: 0,
        pending_noinline: 0,
        pending_must_use: 0,
        pending_panic_handler: 0,
        pending_entry: 0,
        pending_no_main: 0,
        pending_test: 0,
        pending_before: 0,
        pending_after: 0,
        pending_derive_start: 0,
        pending_derive_count: 0,
        pending_sealed: 0,
        pending_flags: 0,
        saw_implicit_it: 0,
        implicit_it_depth: 0,
        last_param_pattern_start: 0,
        last_param_pattern_count: 0,
        last_param_required_count: 0,
        last_where_start: 0,
        last_where_count: 0,
    }

// ── Token helpers ────────────────────────────────────────────────

fn Parser.peek(self: Parser) -> i32:
    if self.pos >= self.tokens.len():
        return TK_EOF
    self.tokens.get_tag(self.pos)

fn Parser.advance(self: Parser):
    if self.pos < self.tokens.len():
        self.pos = self.pos + 1

fn Parser.current_start(self: Parser) -> i32:
    if self.pos >= self.tokens.len():
        return 0
    self.tokens.get_start(self.pos)

fn Parser.current_end(self: Parser) -> i32:
    if self.pos >= self.tokens.len():
        return 0
    self.tokens.get_end(self.pos)

fn Parser.prev_start(self: Parser) -> i32:
    if self.pos == 0:
        return 0
    self.tokens.get_start(self.pos - 1)

fn Parser.prev_end(self: Parser) -> i32:
    if self.pos == 0:
        return 0
    self.tokens.get_end(self.pos - 1)

fn Parser.expect(self: Parser, expected: i32) -> i32:
    if self.peek() != expected:
        self.emit_error("expected " ++ tag_name(expected))
        return 0
    self.advance()
    1

fn Parser.expect_ident(self: Parser) -> i32:
    if self.peek() != TK_IDENT:
        self.emit_error("expected identifier")
        return 0
    let sym = self.intern_current()
    self.advance()
    sym

fn Parser.expect_ident_or_keyword(self: Parser) -> i32:
    let t = self.peek()
    if t == TK_IDENT or (t >= TK_KW_FN and t <= TK_KW_OR):
        let sym = self.intern_current()
        self.advance()
        return sym
    self.emit_error("expected identifier")
    0

fn Parser.intern_current(self: Parser) -> i32:
    let s = self.current_start()
    let e = self.current_end()
    let text = self.source.slice(s as i64, e as i64)
    self.intern.intern(text)

fn Parser.is_ident_named(self: Parser, name: str) -> bool:
    if self.peek() != TK_IDENT:
        return false
    let s = self.current_start()
    let e = self.current_end()
    self.source.slice(s as i64, e as i64) == name

fn Parser.skip_newlines(self: Parser):
    while self.peek() == TK_NEWLINE:
        self.advance()

fn Parser.peek_past_newlines(self: Parser) -> i32:
    var p = self.pos
    while p < self.tokens.len() and self.tokens.get_tag(p) == TK_NEWLINE:
        p = p + 1
    if p < self.tokens.len():
        return self.tokens.get_tag(p)
    TK_EOF

fn Parser.emit_error(self: Parser, msg: str):
    let span = Span { file: self.file_id, start: self.current_start(), end: self.current_end() }
    self.diags.emit(Diagnostic.err(msg, span))

fn Parser.recover_to_top_level(self: Parser):
    while self.peek() != TK_EOF:
        let t = self.peek()
        if t == TK_AT or
           t == TK_KW_FN or t == TK_KW_TYPE or t == TK_KW_USE or t == TK_KW_LET or
           t == TK_KW_VAR or t == TK_KW_PUB or t == TK_KW_EXTERN or t == TK_KW_ERROR or
           t == TK_KW_TRAIT or t == TK_KW_IMPL or t == TK_KW_EXTEND or t == TK_KW_ASYNC or
           t == TK_KW_GEN or t == TK_KW_COMPTIME:
            return
        self.advance()

// ── Attribute parsing ────────────────────────────────────────────

fn Parser.skip_attributes(self: Parser):
    self.pending_derive_start = 0
    self.pending_derive_count = 0
    self.pending_tailrec = 0
    self.pending_inline = 0
    self.pending_noinline = 0
    self.pending_must_use = 0
    self.pending_panic_handler = 0
    self.pending_entry = 0
    self.pending_no_main = 0
    self.pending_test = 0
    self.pending_before = 0
    self.pending_after = 0
    self.pending_sealed = 0
    self.pending_flags = 0
    var derive_syms: Vec[i32] = Vec.new()

    while self.peek() == TK_AT:
        let saved = self.pos
        self.advance()
        if self.peek() != TK_L_BRACKET:
            self.pos = saved
            return
        self.advance()

        // Check for must_use and flags BEFORE the else-if chain
        if self.peek() == TK_IDENT:
            let attr_s = self.current_start()
            let attr_e = self.current_end()
            let attr_text = self.source.slice(attr_s as i64, attr_e as i64)
            if attr_text == "must_use":
                self.pending_must_use = 1
            if attr_text == "flags":
                self.pending_flags = 1
            if attr_text == "sealed":
                self.pending_sealed = 1

        if self.is_ident_named("derive"):
            self.advance()
            if self.peek() == TK_L_PAREN:
                self.advance()
                while self.peek() != TK_R_PAREN and self.peek() != TK_EOF:
                    if self.peek() == TK_IDENT:
                        let sym = self.intern_current()
                        self.advance()
                        derive_syms.push(sym)
                    else:
                        self.advance()
                    if self.peek() == TK_COMMA:
                        self.advance()
                        self.skip_newlines()
                if self.peek() == TK_R_PAREN:
                    self.advance()
        else if self.is_ident_named("tailrec"):
            self.pending_tailrec = 1
            self.advance()
        else if self.is_ident_named("inline"):
            self.pending_inline = 1
            self.advance()
        else if self.is_ident_named("noinline"):
            self.pending_noinline = 1
            self.advance()
        else if self.is_ident_named("must_use"):
            // Already handled by standalone check above
            self.advance()
        else if self.is_ident_named("panic_handler"):
            self.pending_panic_handler = 1
            self.advance()
        else if self.is_ident_named("entry"):
            self.pending_entry = 1
            self.advance()
        else if self.is_ident_named("no_main"):
            self.pending_no_main = 1
            self.advance()
        else if self.is_ident_named("test"):
            self.pending_test = 1
            self.advance()
        else if self.is_ident_named("before"):
            self.pending_before = 1
            self.advance()
        else if self.is_ident_named("after"):
            self.pending_after = 1
            self.advance()
        else if self.is_ident_named("sealed"):
            // Already handled by standalone check above
            self.advance()
        else if self.is_ident_named("flags"):
            // Already handled by standalone check above
            self.advance()

        // consume until matching ]
        var depth = 1
        while depth > 0 and self.peek() != TK_EOF:
            if self.peek() == TK_L_BRACKET:
                depth = depth + 1
            if self.peek() == TK_R_BRACKET:
                depth = depth - 1
            self.advance()
        self.skip_newlines()

    // Store derive traits in extra array
    if derive_syms.len() > 0:
        self.pending_derive_start = self.pool.extra_len()
        self.pending_derive_count = derive_syms.len() as i32
        for i in 0..derive_syms.len() as i32:
            self.pool.add_extra(derive_syms.get(i as i64))

// ── Module parsing ───────────────────────────────────────────────

fn Parser.parse_module(self: Parser) -> AstPool:
    self.skip_newlines()

    // Skip optional module declaration
    if self.peek() == TK_KW_MODULE:
        self.advance()
        if self.peek() == TK_IDENT or self.peek() == TK_DOT_IDENT:
            self.advance()
        while true:
            if self.peek() == TK_DOT:
                self.advance()
                if self.peek() == TK_IDENT:
                    self.advance()
                else:
                    break
            else if self.peek() == TK_DOT_IDENT:
                // .Uppercase segments are lexed as dot-identifiers.
                self.advance()
            else:
                break
        self.skip_newlines()

    while self.peek() != TK_EOF:
        self.skip_newlines()
        self.skip_attributes()
        self.skip_newlines()
        if self.peek() == TK_EOF:
            break

        if self.peek() == TK_KW_PUB:
            let saved_pos = self.pos
            self.advance()
            if self.peek() == TK_KW_IMPL or self.peek() == TK_KW_EXTEND:
                self.parse_impl_block(VIS_PUBLIC)
                self.skip_newlines()
                continue
            if self.peek() == TK_KW_TRAIT:
                self.parse_trait_decl(VIS_PUBLIC)
                self.skip_newlines()
                continue
            self.pos = saved_pos
        else if self.peek() == TK_KW_IMPL or self.peek() == TK_KW_EXTEND:
            self.parse_impl_block(VIS_PRIVATE)
            self.skip_newlines()
            continue
        else if self.peek() == TK_KW_TRAIT:
            self.parse_trait_decl(VIS_PRIVATE)
            self.skip_newlines()
            continue

        let decl = self.parse_decl()
        if decl != 0:
            self.pool.add_decl(decl)
        else:
            self.recover_to_top_level()
        self.skip_newlines()

    self.pool

// ── Declaration parsing ──────────────────────────────────────────

fn Parser.parse_decl(self: Parser) -> i32:
    var is_pub = VIS_PRIVATE
    let start = self.current_start()

    if self.peek() == TK_KW_PUB:
        is_pub = VIS_PUBLIC
        self.advance()

    if self.peek() != TK_KW_TYPE:
        self.pending_derive_start = 0
        self.pending_derive_count = 0

    let t = self.peek()
    if t == TK_KW_FN:
        return self.parse_fn_decl(is_pub, start, 0, 0, 0)
    if t == TK_KW_COMPTIME:
        self.advance()
        if self.peek() != TK_KW_FN:
            self.emit_error("expected 'fn' after 'comptime'")
            return 0
        return self.parse_fn_decl(is_pub, start, 0, 0, 1)
    if t == TK_KW_ASYNC:
        self.advance()
        return self.parse_fn_decl(is_pub, start, 1, 0, 0)
    if t == TK_KW_GEN:
        self.advance()
        return self.parse_fn_decl(is_pub, start, 0, 1, 0)
    if t == TK_KW_TYPE:
        return self.parse_type_decl(is_pub, start)
    if t == TK_KW_USE:
        return self.parse_use_decl(start)
    if t == TK_KW_LET or t == TK_KW_VAR:
        return self.parse_top_level_let(is_pub, start)
    if t == TK_KW_EXTERN:
        return self.parse_extern_decl(start)
    if t == TK_KW_ERROR:
        return self.parse_error_decl(is_pub, start)
    if t == TK_KW_CONST:
        return self.parse_const_decl(is_pub, start)

    self.emit_error("expected declaration (fn, type, let, use, extern)")
    0

// ── fn decl ──────────────────────────────────────────────────────

fn Parser.parse_fn_decl(self: Parser, is_pub: i32, start: i32, is_async: i32, is_gen: i32, is_comptime: i32) -> i32:
    if self.expect(TK_KW_FN) == 0:
        return 0
    var name = self.expect_ident_or_keyword()
    if name == 0:
        return 0

    // Method syntax: fn Type.method(...)
    if self.peek() == TK_DOT:
        self.advance()
        let method_name = self.expect_ident_or_keyword()
        if method_name == 0:
            return 0
        let type_str = self.intern.resolve(name)
        let method_str = self.intern.resolve(method_name)
        name = self.intern.intern(type_str ++ "." ++ method_str)

    // Type parameters
    let tp_start = self.pool.extra_len()
    var tp_count = self.parse_type_params()

    // Parameters
    var params_start = 0
    var param_count = 0
    var required_param_count = 0
    self.last_param_pattern_start = self.pool.fn_param_patterns_len()
    self.last_param_pattern_count = 0
    if self.peek() == TK_L_PAREN:
        self.advance()
        param_count = self.parse_param_list()
        required_param_count = self.last_param_required_count
        if param_count > 0:
            params_start = self.pool.extra_len() - param_count * 2
        if self.expect(TK_R_PAREN) == 0:
            return 0

    // Return type
    var ret_type = 0
    if self.peek() == TK_ARROW:
        self.advance()
        ret_type = self.parse_type_expr()

    // Where clause
    self.parse_optional_where_clause()

    // Body
    if self.peek() == TK_EQ or self.peek() == TK_COLON:
        self.advance()
    else:
        self.emit_error("expected '=' or ':'")
        return 0
    let body = self.parse_block_or_expr()
    if body == 0:
        return 0

    // Build flags
    var flags = 0
    if is_pub == VIS_PUBLIC:
        flags = flags + FN_FLAG_PUB
    if is_async != 0:
        flags = flags + FN_FLAG_ASYNC
    if is_gen != 0:
        flags = flags + FN_FLAG_GEN
    if is_comptime != 0:
        flags = flags + FN_FLAG_COMPTIME
    if self.pending_tailrec != 0:
        flags = flags + FN_FLAG_TAILREC
    if self.pending_must_use != 0:
        flags = flags + FN_FLAG_MUST_USE
    if self.pending_inline != 0:
        flags = flags + FN_FLAG_INLINE
    if self.pending_noinline != 0:
        flags = flags + FN_FLAG_NOINLINE
    if self.pending_panic_handler != 0:
        flags = flags + FN_FLAG_PANIC_HANDLER
    if self.pending_entry != 0:
        flags = flags + FN_FLAG_ENTRY
    if self.pending_no_main != 0:
        flags = flags + FN_FLAG_NO_MAIN
    if self.pending_test != 0:
        flags = flags + FN_FLAG_TEST
    if self.pending_before != 0:
        flags = flags + FN_FLAG_BEFORE
    if self.pending_after != 0:
        flags = flags + FN_FLAG_AFTER

    // Store extra: type params then params already in extra from parsing.
    // We encode: d0=name, d1=body, d2=flags
    let fn_node = self.pool.add_node(NK_FN_DECL, start, self.pool.get_end(body), name, body, flags)
    let meta_flags = flags + required_param_count * FN_META_REQUIRED_UNIT
    self.pool.add_fn_meta(fn_node, meta_flags, ret_type, params_start, param_count, tp_start, tp_count)
    self.pool.add_fn_param_pattern_meta(fn_node, self.last_param_pattern_start, self.last_param_pattern_count)
    if self.last_where_count > 0:
        self.pool.add_where_meta(fn_node, self.last_where_start, self.last_where_count)
    fn_node

// ── extern fn ────────────────────────────────────────────────────

fn Parser.parse_extern_decl(self: Parser, start: i32) -> i32:
    if self.expect(TK_KW_EXTERN) == 0:
        return 0
    // Optional ABI string: extern "C" fn ...
    if self.peek() == TK_STRING_LIT:
        self.advance()
    if self.expect(TK_KW_FN) == 0:
        return 0
    let name = self.expect_ident()
    if name == 0:
        return 0
    if self.expect(TK_L_PAREN) == 0:
        return 0

    let param_count = self.parse_param_list()
    let extra_start = if param_count > 0:
        self.pool.extra_len() - param_count * 2
    else:
        self.pool.extra_len()

    var is_variadic = 0
    if self.peek() == TK_DOT_DOT_DOT:
        is_variadic = 1
        self.advance()

    if self.expect(TK_R_PAREN) == 0:
        return 0

    var ret_type = 0
    if self.peek() == TK_ARROW:
        self.advance()
        ret_type = self.parse_type_expr()

    // Store: d0=name, d1=extra_start, d2=flags(bit0=variadic)
    // Extra already has [param_name, param_type]* from parse_param_list
    let extern_node = self.pool.add_node(NK_EXTERN_FN, start, self.prev_end(), name, extra_start, is_variadic)
    // Add fn_meta so Codegen can access param_count and return_type
    let required_param_count = self.last_param_required_count
    let meta_flags = is_variadic + required_param_count * FN_META_REQUIRED_UNIT
    self.pool.add_fn_meta(extern_node, meta_flags, ret_type, extra_start, param_count, 0, 0)
    extern_node

// ── type decl ────────────────────────────────────────────────────

fn Parser.parse_type_decl(self: Parser, is_pub: i32, start: i32) -> i32:
    if self.expect(TK_KW_TYPE) == 0:
        return 0
    let name = self.expect_ident()
    if name == 0:
        return 0

    let tp_start = self.pool.extra_len()
    let tp_count = self.parse_type_params()
    self.parse_optional_where_clause()

    // Check for repr type: type Name: i32 = ...
    var repr_type_node = 0
    if self.peek() == TK_COLON:
        self.advance()
        repr_type_node = self.parse_type_expr()

    if self.expect(TK_EQ) == 0:
        return 0
    self.skip_newlines()

    var is_ephemeral = 0

    // Check for ephemeral
    if self.peek() == TK_KW_EPHEMERAL:
        is_ephemeral = 1
        self.advance()
        self.skip_newlines()

    // Discriminant enum: type Name: repr_type = Variant1 | Variant2 = 5 | ...
    if repr_type_node != 0:
        let extra_start = self.parse_disc_enum_variants(repr_type_node)
        self.pool.add_extra(is_pub)
        self.pool.add_extra(tp_start)
        self.pool.add_extra(tp_count)
        let node = self.pool.add_node(NK_TYPE_DECL, start, self.prev_end(), name, extra_start, pack_type_decl_kind(TDK_DISC_ENUM, is_ephemeral))
        return self.finish_type_decl(node)

    // Struct: { field: Type, ... }
    if self.peek() == TK_L_BRACE:
        let extra_start = self.parse_struct_body()
        self.pool.add_extra(is_pub)
        self.pool.add_extra(tp_start)
        self.pool.add_extra(tp_count)
        let node = self.pool.add_node(NK_TYPE_DECL, start, self.prev_end(), name, extra_start, pack_type_decl_kind(TDK_STRUCT, is_ephemeral))
        return self.finish_type_decl(node)

    // Enum: starts with | or Identifier followed by |
    if self.peek() == TK_PIPE:
        let extra_start = self.parse_enum_variants()
        self.pool.add_extra(is_pub)
        self.pool.add_extra(tp_start)
        self.pool.add_extra(tp_count)
        let node = self.pool.add_node(NK_TYPE_DECL, start, self.prev_end(), name, extra_start, pack_type_decl_kind(TDK_ENUM, is_ephemeral))
        return self.finish_type_decl(node)

    if self.peek() == TK_IDENT and self.is_enum_def():
        let extra_start = self.parse_enum_variants()
        self.pool.add_extra(is_pub)
        self.pool.add_extra(tp_start)
        self.pool.add_extra(tp_count)
        let node = self.pool.add_node(NK_TYPE_DECL, start, self.prev_end(), name, extra_start, pack_type_decl_kind(TDK_ENUM, is_ephemeral))
        return self.finish_type_decl(node)

    // Distinct type
    if self.peek() == TK_IDENT and self.is_ident_named("distinct"):
        self.advance()
        let aliased = self.parse_type_expr()
        let extra_start = self.pool.extra_len()
        self.pool.add_extra(aliased)
        self.pool.add_extra(is_pub)
        self.pool.add_extra(tp_start)
        self.pool.add_extra(tp_count)
        let node = self.pool.add_node(NK_TYPE_DECL, start, self.prev_end(), name, extra_start, pack_type_decl_kind(TDK_DISTINCT, is_ephemeral))
        return self.finish_type_decl(node)

    // Type alias
    if self.peek() == TK_KW_FN or
       self.peek() == TK_IDENT or
       self.peek() == TK_AMPERSAND or
       self.peek() == TK_L_PAREN or
       self.peek() == TK_QUESTION or
       self.peek() == TK_STAR or
       self.peek() == TK_L_BRACKET or
       self.peek() == TK_KW_DYN:
        let aliased = self.parse_type_expr()
        let extra_start = self.pool.extra_len()
        self.pool.add_extra(aliased)
        self.pool.add_extra(is_pub)
        self.pool.add_extra(tp_start)
        self.pool.add_extra(tp_count)
        let node = self.pool.add_node(NK_TYPE_DECL, start, self.prev_end(), name, extra_start, pack_type_decl_kind(TDK_ALIAS, is_ephemeral))
        return self.finish_type_decl(node)

    self.emit_error("expected type body")
    0

fn Parser.finish_type_decl(self: Parser, node: i32) -> i32:
    if self.pending_derive_count > 0:
        self.pool.add_type_meta(node, self.pending_derive_start, self.pending_derive_count)
    self.pending_derive_start = 0
    self.pending_derive_count = 0
    if self.pending_must_use != 0:
        self.pool.mark_must_use_type(node)
    node

fn Parser.parse_struct_body(self: Parser) -> i32:
    self.advance()  // consume {
    self.skip_newlines()
    var fields: Vec[i32] = Vec.new()
    var field_count = 0

    while self.peek() != TK_R_BRACE and self.peek() != TK_EOF:
        let field_name = self.expect_ident()
        if field_name == 0:
            break
        if self.expect(TK_COLON) == 0:
            break
        let field_type = self.parse_type_expr()

        // Optional default value
        var field_default = 0
        if self.peek() == TK_EQ:
            self.advance()
            self.skip_newlines()
            field_default = self.parse_expr()

        fields.push(field_name)
        fields.push(field_type)
        fields.push(field_default)
        field_count = field_count + 1

        self.skip_newlines()
        if self.peek() == TK_COMMA:
            self.advance()
            self.skip_newlines()

    self.expect(TK_R_BRACE)
    let extra_start = self.pool.extra_len()
    self.pool.add_extra(field_count)
    for fi in 0..fields.len() as i32:
        self.pool.add_extra(fields.get(fi as i64))
    extra_start

fn Parser.is_enum_def(self: Parser) -> bool:
    let saved = self.pos
    self.advance()  // skip identifier
    self.skip_newlines()
    if self.peek() == TK_PIPE:
        self.pos = saved
        return true
    if self.peek() == TK_L_PAREN:
        self.advance()
        var depth = 1
        while depth > 0 and self.peek() != TK_EOF:
            if self.peek() == TK_L_PAREN:
                depth = depth + 1
            if self.peek() == TK_R_PAREN:
                depth = depth - 1
            self.advance()
        self.skip_newlines()
        if self.peek() == TK_PIPE:
            self.pos = saved
            return true
    self.pos = saved
    false

fn Parser.parse_enum_variants(self: Parser) -> i32:
    var variants: Vec[i32] = Vec.new()
    var variant_count = 0

    if self.peek() == TK_PIPE:
        self.advance()
        self.skip_newlines()

    while self.peek() == TK_IDENT:
        let vname = self.expect_ident()
        var payloads: Vec[i32] = Vec.new()

        if self.peek() == TK_L_PAREN:
            self.advance()
            while self.peek() != TK_R_PAREN and self.peek() != TK_EOF:
                // Support named payload fields: Variant(name: Type, ...)
                if self.peek() == TK_IDENT and
                   self.pos + 1 < self.tokens.len() and
                   self.tokens.get_tag(self.pos + 1) == TK_COLON:
                    self.advance()
                    self.advance()
                    self.skip_newlines()

                let before_payload = self.pos
                let pty = self.parse_type_expr()
                payloads.push(pty)
                if self.peek() == TK_COMMA:
                    self.advance()
                    self.skip_newlines()
                else if self.peek() != TK_R_PAREN and self.peek() != TK_EOF:
                    self.emit_error("expected ',' or ')' in enum payload")
                    if self.pos == before_payload:
                        self.advance()
            self.expect(TK_R_PAREN)

        variants.push(vname)
        variants.push(payloads.len() as i32)
        for pi in 0..payloads.len() as i32:
            variants.push(payloads.get(pi as i64))
        variant_count = variant_count + 1

        self.skip_newlines()
        if self.peek() == TK_PIPE:
            self.advance()
            self.skip_newlines()
            continue
        if self.peek() == TK_IDENT:
            continue
        break

    let extra_start = self.pool.extra_len()
    self.pool.add_extra(variant_count)
    for vi in 0..variants.len() as i32:
        self.pool.add_extra(variants.get(vi as i64))
    extra_start

fn Parser.parse_disc_enum_variants(self: Parser, repr_type_node: i32) -> i32:
    var variants: Vec[i32] = Vec.new()
    var variant_count = 0
    var current_disc = 0

    if self.pending_flags != 0:
        current_disc = 1

    if self.peek() == TK_PIPE:
        self.advance()
        self.skip_newlines()

    while self.peek() == TK_IDENT:
        let vname = self.expect_ident()

        // Optional payload
        var payloads: Vec[i32] = Vec.new()
        if self.peek() == TK_L_PAREN:
            self.advance()
            while self.peek() != TK_R_PAREN and self.peek() != TK_EOF:
                if self.peek() == TK_IDENT and
                   self.pos + 1 < self.tokens.len() and
                   self.tokens.get_tag(self.pos + 1) == TK_COLON:
                    self.advance()
                    self.advance()
                    self.skip_newlines()
                let pty = self.parse_type_expr()
                payloads.push(pty)
                if self.peek() == TK_COMMA:
                    self.advance()
                    self.skip_newlines()
                else if self.peek() != TK_R_PAREN and self.peek() != TK_EOF:
                    self.emit_error("expected ',' or ')' in enum payload")
                    self.advance()
            self.expect(TK_R_PAREN)

        // Optional explicit discriminant: = value
        if self.peek() == TK_EQ:
            self.advance()
            self.skip_newlines()
            var negate = 0
            if self.peek() == TK_MINUS:
                negate = 1
                self.advance()
            if self.peek() == TK_INT_LIT:
                let text = self.source.slice(self.current_start() as i64, self.current_end() as i64)
                let val = parse_i64(text) as i32
                if negate != 0:
                    current_disc = 0 - val
                else:
                    current_disc = val
                self.advance()
            else:
                self.emit_error("expected integer literal for discriminant value")

        variants.push(vname)
        variants.push(current_disc)
        variants.push(payloads.len() as i32)
        for pi in 0..payloads.len() as i32:
            variants.push(payloads.get(pi as i64))
        variant_count = variant_count + 1

        // Auto-increment for next variant
        if self.pending_flags != 0:
            current_disc = current_disc * 2
        else:
            current_disc = current_disc + 1

        self.skip_newlines()
        if self.peek() == TK_PIPE:
            self.advance()
            self.skip_newlines()
            continue
        if self.peek() == TK_IDENT:
            continue
        break

    let extra_start = self.pool.extra_len()
    self.pool.add_extra(repr_type_node)
    self.pool.add_extra(variant_count)
    for vi in 0..variants.len() as i32:
        self.pool.add_extra(variants.get(vi as i64))
    extra_start

// ── use decl ─────────────────────────────────────────────────────

fn Parser.parse_use_decl(self: Parser, start: i32) -> i32:
    if self.expect(TK_KW_USE) == 0:
        return 0

    // use c_import("header.h")
    if self.peek() == TK_KW_C_IMPORT:
        return self.parse_c_import(start)

    let extra_start = self.pool.extra_len()
    var path_count = 0

    let first = self.peek()
    if first == TK_IDENT or (first >= TK_KW_FN and first <= TK_KW_OR):
        let sym = self.expect_ident_or_keyword()
        self.pool.add_extra(sym)
        path_count = path_count + 1

    while true:
        if self.peek() == TK_DOT:
            self.advance()
            let next = self.peek()
            if next == TK_IDENT or (next >= TK_KW_FN and next <= TK_KW_OR):
                let sym = self.expect_ident_or_keyword()
                self.pool.add_extra(sym)
                path_count = path_count + 1
            else if self.peek() == TK_STAR:
                self.advance()
                break
            else if self.peek() == TK_L_BRACE:
                self.advance()
                while self.peek() != TK_R_BRACE and self.peek() != TK_EOF and self.peek() != TK_NEWLINE:
                    self.advance()
                if self.peek() == TK_R_BRACE:
                    self.advance()
                break
            else:
                break
        else if self.peek() == TK_DOT_IDENT:
            let span_s = self.current_start()
            let span_e = self.current_end()
            let text = self.source.slice((span_s + 1) as i64, span_e as i64)
            let sym = self.intern.intern(text)
            self.pool.add_extra(sym)
            path_count = path_count + 1
            self.advance()
        else:
            break

    if path_count == 0:
        self.emit_error("expected import path after 'use'")
        return 0

    // Skip any trailing paren groups
    if self.peek() == TK_L_PAREN:
        var depth = 1
        self.advance()
        while depth > 0 and self.peek() != TK_EOF:
            if self.peek() == TK_L_PAREN:
                depth = depth + 1
            if self.peek() == TK_R_PAREN:
                depth = depth - 1
            self.advance()

    self.pool.add_node(NK_USE_DECL, start, self.prev_end(), extra_start, path_count, 0)

fn Parser.parse_c_import(self: Parser, start: i32) -> i32:
    self.advance()  // consume c_import
    if self.expect(TK_L_PAREN) == 0:
        return 0
    if self.peek() != TK_STRING_LIT:
        self.emit_error("expected string literal after c_import(")
        return 0
    let str_s = self.current_start()
    let str_e = self.current_end()
    let raw = self.source.slice((str_s + 1) as i64, (str_e - 1) as i64)
    let header_sym = self.intern.intern(raw)
    self.advance()

    let extra_start = self.pool.extra_len()
    var link_count = 0

    if self.peek() == TK_COMMA:
        self.advance()
        self.skip_newlines()
        if self.peek() == TK_IDENT:
            self.advance()  // skip 'link'
        if self.expect(TK_COLON) == 0:
            return 0
        self.skip_newlines()
        while self.peek() == TK_STRING_LIT:
            let ls = self.current_start()
            let le = self.current_end()
            let lib = self.source.slice((ls + 1) as i64, (le - 1) as i64)
            let lib_sym = self.intern.intern(lib)
            self.pool.add_extra(lib_sym)
            link_count = link_count + 1
            self.advance()
            self.skip_newlines()
            if self.peek() == TK_COMMA:
                let cp = self.pos
                self.advance()
                self.skip_newlines()
                if self.peek() == TK_STRING_LIT:
                    continue
                self.pos = cp
            break

    self.expect(TK_R_PAREN)
    self.pool.add_node(NK_C_IMPORT, start, self.prev_end(), header_sym, extra_start, link_count)

// ── let decl ─────────────────────────────────────────────────────

fn Parser.parse_top_level_let(self: Parser, is_pub: i32, start: i32) -> i32:
    let is_var = self.peek() == TK_KW_VAR
    self.advance()
    var is_mut = is_var
    if not is_var and self.peek() == TK_KW_MUT:
        is_mut = true
        self.advance()
    let name = self.expect_ident()
    if name == 0:
        return 0

    var type_ann = 0
    if self.peek() == TK_COLON:
        self.advance()
        type_ann = self.parse_type_expr()

    if self.expect(TK_EQ) == 0:
        return 0
    self.skip_newlines()
    let value = self.parse_expr()
    if value == 0:
        return 0

    var flags = 0
    if is_mut:
        flags = flags + 1
    if is_pub == VIS_PUBLIC:
        flags = flags + 2
    if type_ann != 0:
        let type_extra = self.pool.extra_len()
        self.pool.add_extra(type_ann)
        // Keep lower 2 bits for mut/pub; encode optional type at bit 2+.
        flags = flags + (type_extra + 1) * 4

    self.pool.add_node(NK_LET_DECL, start, self.prev_end(), name, value, flags)

fn Parser.parse_const_decl(self: Parser, is_pub: i32, start: i32) -> i32:
    self.advance()  // consume 'const'
    let name = self.expect_ident()
    if name == 0:
        return 0

    if self.peek() != TK_COLON:
        self.emit_error("const declaration requires a type annotation")
        return 0
    self.advance()
    let type_ann = self.parse_type_expr()

    if self.expect(TK_EQ) == 0:
        return 0
    self.skip_newlines()
    let raw_value = self.parse_expr()
    if raw_value == 0:
        return 0
    // const desugars to comptime-wrapped immutable let
    let value = self.pool.add_node(NK_COMPTIME, start, self.prev_end(), raw_value, 0, 0)

    var flags = 0
    if is_pub == VIS_PUBLIC:
        flags = flags + 2
    if type_ann != 0:
        let type_extra = self.pool.extra_len()
        self.pool.add_extra(type_ann)
        flags = flags + (type_extra + 1) * 4

    self.pool.add_node(NK_LET_DECL, start, self.prev_end(), name, value, flags)

// ── error decl (desugars to enum) ────────────────────────────────

fn Parser.parse_error_decl(self: Parser, is_pub: i32, start: i32) -> i32:
    self.advance()  // consume 'error'
    let err_name = self.expect_ident()
    if err_name == 0:
        return 0

    // error Name from OtherError, ...
    if self.is_ident_named("from"):
        self.advance()
        let extra_start = self.pool.extra_len()
        var variant_count = 0
        let count_idx = self.pool.add_extra(0)
        while true:
            let src_sym = self.expect_ident()
            if src_sym == 0:
                break
            self.pool.add_extra(src_sym)
            self.pool.add_extra(0)  // payload count = 0
            variant_count = variant_count + 1
            if self.peek() != TK_COMMA:
                break
            self.advance()
            self.skip_newlines()
        self.pool.extra.set_i32(count_idx as i64, variant_count)
        self.pool.add_extra(is_pub)
        self.pool.add_extra(0)
        self.pool.add_extra(0)
        return self.pool.add_node(NK_TYPE_DECL, start, self.prev_end(), err_name, extra_start, pack_type_decl_kind(TDK_ENUM, 0))

    // error Name = Variant1, Variant2(payload), ...
    if self.expect(TK_EQ) == 0:
        return 0
    self.skip_newlines()

    let extra_start = self.parse_enum_variants()
    self.pool.add_extra(is_pub)
    self.pool.add_extra(0)
    self.pool.add_extra(0)
    self.pool.add_node(NK_TYPE_DECL, start, self.prev_end(), err_name, extra_start, pack_type_decl_kind(TDK_ENUM, 0))

// ── trait decl ───────────────────────────────────────────────────

fn Parser.parse_trait_decl(self: Parser, vis: i32):
    let start = self.current_start()
    if self.peek() == TK_KW_PUB:
        self.advance()
    if self.expect(TK_KW_TRAIT) == 0:
        return
    let name = self.expect_ident()
    if name == 0:
        return
    // Parse optional type parameters: trait Iter[T] = ...
    let trait_tp_start = self.pool.extra_len()
    let trait_tp_count = self.parse_type_params()
    if self.peek() == TK_EQ or self.peek() == TK_COLON:
        self.advance()
    else:
        self.emit_error("expected '=' or ':'")
        return
    self.skip_newlines()

    var method_names: Vec[i32] = Vec.new()
    var method_flags: Vec[i32] = Vec.new()
    var method_param_starts: Vec[i32] = Vec.new()
    var method_param_counts: Vec[i32] = Vec.new()
    var method_ret_types: Vec[i32] = Vec.new()
    var method_bodies: Vec[i32] = Vec.new()

    var assoc_names: Vec[i32] = Vec.new()
    var assoc_bound_starts: Vec[i32] = Vec.new()
    var assoc_bound_counts: Vec[i32] = Vec.new()
    var assoc_default_types: Vec[i32] = Vec.new()
    var assoc_bounds_flat: Vec[i32] = Vec.new()

    while self.peek() == TK_KW_FN or self.peek() == TK_KW_PUB or self.peek() == TK_KW_TYPE or self.peek() == TK_KW_ASYNC:
        let fn_col = column_of(self.source, self.current_start())
        if fn_col == 0:
            break

        if self.peek() == TK_KW_TYPE:
            self.advance()
            let at_name = self.expect_ident()
            let bound_start = assoc_bounds_flat.len() as i32
            var bound_count = 0
            if self.peek() == TK_COLON:
                self.advance()
                let b = self.parse_type_bound_symbol()
                if b != 0:
                    assoc_bounds_flat.push(b)
                    bound_count = bound_count + 1
                while self.peek() == TK_PLUS:
                    self.advance()
                    let b2 = self.parse_type_bound_symbol()
                    if b2 != 0:
                        assoc_bounds_flat.push(b2)
                        bound_count = bound_count + 1
            var default_ty = 0
            if self.peek() == TK_EQ:
                self.advance()
                default_ty = self.parse_type_expr()
            assoc_names.push(at_name)
            assoc_bound_starts.push(bound_start)
            assoc_bound_counts.push(bound_count)
            assoc_default_types.push(default_ty)
            self.skip_newlines()
            continue

        var is_pub_method = 0
        if self.peek() == TK_KW_PUB:
            is_pub_method = 1
            self.advance()
        var is_async_method = 0
        if self.peek() == TK_KW_ASYNC:
            is_async_method = 1
            self.advance()
        if self.expect(TK_KW_FN) == 0:
            break
        let mname = self.expect_ident_or_keyword()
        let m_tp_count = self.parse_type_params()

        var params_start = 0
        var param_count = 0
        if self.peek() == TK_L_PAREN:
            self.advance()
            param_count = self.parse_param_list()
            if param_count > 0:
                params_start = self.pool.extra_len() - param_count * 2
            self.expect(TK_R_PAREN)

        var ret_type = 0
        if self.peek() == TK_ARROW:
            self.advance()
            ret_type = self.parse_type_expr()

        self.parse_optional_where_clause()

        var method_body = 0
        if self.peek() == TK_EQ or self.peek() == TK_COLON:
            self.advance()
            method_body = self.parse_block_or_expr()

        method_names.push(mname)
        method_param_starts.push(params_start)
        method_param_counts.push(param_count)
        method_ret_types.push(ret_type)
        method_bodies.push(method_body)
        var mflags = 0
        if is_async_method != 0:
            mflags = mflags + 1
        if is_pub_method != 0:
            mflags = mflags + 2
        if m_tp_count > 0:
            mflags = mflags + 4
        method_flags.push(mflags)
        self.skip_newlines()

    let extra_start = self.pool.extra_len()
    // Type params: count and start index into extra pool
    self.pool.add_extra(trait_tp_count)
    self.pool.add_extra(trait_tp_start)
    let assoc_count = assoc_names.len() as i32
    self.pool.add_extra(assoc_count)
    for ai in 0..assoc_count:
        self.pool.add_extra(assoc_names.get(ai as i64))
        let bound_start = assoc_bound_starts.get(ai as i64)
        let bound_count = assoc_bound_counts.get(ai as i64)
        self.pool.add_extra(bound_count)
        for bi in 0..bound_count:
            self.pool.add_extra(assoc_bounds_flat.get((bound_start + bi) as i64))
        self.pool.add_extra(assoc_default_types.get(ai as i64))

    let method_count = method_names.len() as i32
    self.pool.add_extra(method_count)
    for mi in 0..method_count:
        self.pool.add_extra(method_names.get(mi as i64))
        self.pool.add_extra(method_flags.get(mi as i64))
        self.pool.add_extra(method_param_starts.get(mi as i64))
        self.pool.add_extra(method_param_counts.get(mi as i64))
        self.pool.add_extra(method_ret_types.get(mi as i64))
        self.pool.add_extra(method_bodies.get(mi as i64))

    let node = self.pool.add_node(NK_TRAIT_DECL, start, self.prev_end(), name, extra_start, vis)
    if self.pending_sealed != 0:
        self.pool.mark_sealed_trait(node)
    self.pool.add_decl(node)

// ── impl/extend block ────────────────────────────────────────────

// Parse optional generic type args after an impl target type name.
// e.g., for `impl Trait for Vec[i32]`, parses `[i32]` after "Vec".
// Returns NK_TYPE_GENERIC node if args present, 0 otherwise.
fn Parser.parse_optional_impl_target_args(self: Parser, type_name: i32) -> i32:
    if self.peek() != TK_L_BRACKET:
        return 0
    let start = self.current_start()
    self.advance()
    var args: Vec[i32] = Vec.new()
    while self.peek() != TK_R_BRACKET and self.peek() != TK_EOF:
        let ty = self.parse_type_expr()
        args.push(ty)
        if self.peek() != TK_COMMA:
            break
        self.advance()
    self.expect(TK_R_BRACKET)
    let extra_start = self.pool.extra_len()
    for ai in 0..args.len() as i32:
        self.pool.add_extra(args.get(ai as i64))
    self.pool.add_node(NK_TYPE_GENERIC, start, self.prev_end(), type_name, extra_start, args.len() as i32)

fn Parser.parse_impl_block(self: Parser, vis: i32):
    let start = self.current_start()
    if self.peek() == TK_KW_PUB:
        self.advance()
    if self.peek() == TK_KW_IMPL:
        self.advance()
    else if self.peek() == TK_KW_EXTEND:
        self.advance()
    else:
        return

    // Check for impl-level type parameters: impl[T: Bound] Trait for T
    var impl_tp_start = 0
    var impl_tp_count = 0
    if self.peek() == TK_L_BRACKET:
        impl_tp_start = self.pool.extra_len()
        impl_tp_count = self.parse_type_params()

    let first_name = self.expect_ident()
    if first_name == 0:
        return

    var trait_name = 0
    var type_name = first_name
    var target_type_node = 0
    var trait_arg_extra_start = 0
    var trait_arg_count = 0
    if self.peek() == TK_L_BRACKET:
        self.advance()
        trait_arg_extra_start = self.pool.extra_len()
        while self.peek() != TK_R_BRACKET and self.peek() != TK_EOF:
            let arg = self.parse_type_expr()
            self.pool.add_extra(arg)
            trait_arg_count = trait_arg_count + 1
            if self.peek() == TK_COMMA:
                self.advance()
        self.expect(TK_R_BRACKET)
        if self.peek() != TK_KW_FOR:
            self.emit_error("expected 'for' after trait generic arguments in impl")
            return
        self.advance()
        trait_name = first_name
        type_name = self.expect_ident()
        if type_name == 0:
            return
        target_type_node = self.parse_optional_impl_target_args(type_name)
    else if self.peek() == TK_KW_FOR:
        self.advance()
        trait_name = first_name
        type_name = self.expect_ident()
        if type_name == 0:
            return
        target_type_node = self.parse_optional_impl_target_args(type_name)

    // Defensive fallback: if `for` was not consumed above, consume it now.
    if trait_name == 0 and (self.peek() == TK_KW_FOR or self.is_ident_named("for")):
        self.advance()
        trait_name = first_name
        type_name = self.expect_ident()
        if type_name == 0:
            return
        target_type_node = self.parse_optional_impl_target_args(type_name)

    self.parse_optional_where_clause()

    if self.peek() == TK_EQ or self.peek() == TK_COLON:
        self.advance()
    self.skip_newlines()

    var impl_assoc_names: Vec[i32] = Vec.new()
    var impl_assoc_types: Vec[i32] = Vec.new()
    let extra_start = self.pool.extra_len()
    var method_count = 0

    while self.peek() == TK_KW_FN or self.peek() == TK_KW_PUB or self.peek() == TK_KW_ASYNC or self.peek() == TK_KW_TYPE:
        let fn_col = column_of(self.source, self.current_start())
        if fn_col == 0:
            break

        // Associated type binding: type Name = ConcreteType
        if self.peek() == TK_KW_TYPE:
            self.advance()
            let at_name = self.expect_ident()
            if self.expect(TK_EQ) == 0:
                break
            let at_type = self.parse_type_expr()
            impl_assoc_names.push(at_name)
            impl_assoc_types.push(at_type)
            self.skip_newlines()
            continue

        var method_vis = vis
        let method_start = self.current_start()
        if self.peek() == TK_KW_PUB:
            method_vis = VIS_PUBLIC
            self.advance()
        var m_async = 0
        if self.peek() == TK_KW_ASYNC:
            m_async = 1
            self.advance()
        if self.expect(TK_KW_FN) == 0:
            break
        let method_name_sym = self.expect_ident_or_keyword()
        if method_name_sym == 0:
            break

        // Mangle as Type.method
        let type_str = self.intern.resolve(type_name)
        let method_str = self.intern.resolve(method_name_sym)
        let mangled = self.intern.intern(type_str ++ "." ++ method_str)

        let m_tp_start = self.pool.extra_len()
        let m_tp_count = self.parse_type_params()

        var m_params_start = 0
        var param_count = 0
        var required_param_count = 0
        if self.peek() == TK_L_PAREN:
            self.advance()
            param_count = self.parse_param_list()
            required_param_count = self.last_param_required_count
            if param_count > 0:
                m_params_start = self.pool.extra_len() - param_count * 2
            self.expect(TK_R_PAREN)

        var ret_type = 0
        if self.peek() == TK_ARROW:
            self.advance()
            ret_type = self.parse_type_expr()

        self.parse_optional_where_clause()

        if self.peek() == TK_EQ or self.peek() == TK_COLON:
            self.advance()
        else:
            self.emit_error("expected '=' or ':'")
            break
        let body = self.parse_block_or_expr()

        var flags = 0
        if method_vis == VIS_PUBLIC:
            flags = flags + FN_FLAG_PUB
        if m_async != 0:
            flags = flags + FN_FLAG_ASYNC

        let fn_node = self.pool.add_node(NK_FN_DECL, method_start, self.prev_end(), mangled, body, flags)
        let meta_flags = flags + required_param_count * FN_META_REQUIRED_UNIT
        self.pool.add_fn_meta(fn_node, meta_flags, ret_type, m_params_start, param_count, m_tp_start, m_tp_count)
        self.pool.add_decl(fn_node)
        method_count = method_count + 1
        self.skip_newlines()

    // Emit impl_decl node. Store assoc types + method_count in extra.
    let impl_extra = self.pool.extra_len()
    let impl_assoc_count = impl_assoc_names.len() as i32
    self.pool.add_extra(impl_assoc_count)
    for iai in 0..impl_assoc_count:
        self.pool.add_extra(impl_assoc_names.get(iai as i64))
        self.pool.add_extra(impl_assoc_types.get(iai as i64))
    self.pool.add_extra(method_count)
    let impl_node = self.pool.add_node(NK_IMPL_DECL, start, self.prev_end(), type_name, impl_extra, trait_name)
    self.pool.add_decl(impl_node)

    // Store impl type params if present (blanket impl)
    if impl_tp_count > 0:
        self.pool.add_impl_type_params(impl_node, impl_tp_start, impl_tp_count)

    // Store impl target type node if generic (e.g., impl Trait for Vec[i32])
    if target_type_node != 0:
        self.pool.add_impl_target_type_node(impl_node, target_type_node)

    // Store impl trait type args if present (e.g., impl IntoIter[i32] for Type)
    if trait_arg_count > 0:
        self.pool.add_impl_trait_type_args(impl_node, trait_arg_extra_start, trait_arg_count)

// ── Expression parsing ───────────────────────────────────────────

fn Parser.parse_expr(self: Parser) -> i32:
    let lhs = self.parse_precedence(0)
    if lhs == 0:
        return 0

    // Assignment: lhs = rhs
    if self.peek() == TK_EQ:
        self.advance()
        self.skip_newlines()
        let rhs = self.parse_expr()
        return self.pool.add_node(NK_ASSIGN, self.pool.get_start(lhs), self.prev_end(), lhs, rhs, 0)

    // Compound assignment: += -= *= /= %=
    let cop = self.compound_assign_op()
    if cop >= 0:
        self.advance()
        self.skip_newlines()
        let rhs = self.parse_expr()
        let bin = self.pool.add_node(NK_BINARY, self.pool.get_start(lhs), self.prev_end(), cop, lhs, rhs)
        return self.pool.add_node(NK_ASSIGN, self.pool.get_start(lhs), self.prev_end(), lhs, bin, 0)

    lhs

fn Parser.compound_assign_op(self: Parser) -> i32:
    let t = self.peek()
    if t == TK_PLUS_EQ: return OP_ADD
    if t == TK_MINUS_EQ: return OP_SUB
    if t == TK_STAR_EQ: return OP_MUL
    if t == TK_SLASH_EQ: return OP_DIV
    if t == TK_PERCENT_EQ: return OP_MOD
    -1

// ── Pratt precedence climbing ────────────────────────────────────

fn Parser.parse_precedence(self: Parser, min_prec: i32) -> i32:
    var lhs = self.parse_primary()
    if lhs == 0:
        return 0
    lhs = self.parse_postfix(lhs)

    while true:
        if self.peek() == TK_NEWLINE:
            let next = self.peek_past_newlines()
            if next == TK_PIPE_GT or next == TK_LT_PIPE or next == TK_QUESTION_QUESTION:
                self.skip_newlines()

        let info = self.infix_op()
        if info == 0:
            break
        let prec = info / 1000
        let op_code = info % 1000
        if prec < min_prec:
            break
        self.advance()

        // not in: consume second token
        if op_code == OP_NOT_IN:
            self.advance()
        self.skip_newlines()

        // Pipeline into match
        if op_code == 500 and self.peek() == TK_KW_MATCH:
            self.advance()
            self.skip_newlines()
            let arm_count = self.parse_match_arms()
            let arms_start = if arm_count > 0: self.pool.extra_len() - arm_count else: self.pool.extra_len()
            lhs = self.pool.add_node(NK_MATCH, self.pool.get_start(lhs), self.prev_end(), lhs, arms_start, arm_count)
            continue

        let next_prec = if op_code == OP_DEFAULT or op_code == 501: prec else: prec + 1
        let rhs = self.parse_precedence(next_prec)

        if op_code == 500:  // pipeline
            lhs = self.pool.add_node(NK_PIPELINE, self.pool.get_start(lhs), self.prev_end(), lhs, rhs, 0)
        else if op_code == 501:  // reverse pipeline
            lhs = self.pool.add_node(NK_PIPELINE, self.pool.get_start(lhs), self.prev_end(), rhs, lhs, 0)
        else if op_code == 504:  // backward compose <<
            lhs = self.build_composed_closure(lhs, rhs, 0)
        else if op_code == 505:  // forward compose >>
            lhs = self.build_composed_closure(lhs, rhs, 1)
        else if op_code == 502:  // range ..
            lhs = self.pool.add_node(NK_RANGE, self.pool.get_start(lhs), self.prev_end(), lhs, rhs, 0)
        else if op_code == 503:  // range ..=
            lhs = self.pool.add_node(NK_RANGE, self.pool.get_start(lhs), self.prev_end(), lhs, rhs, 1)
        else:
            lhs = self.pool.add_node(NK_BINARY, self.pool.get_start(lhs), self.prev_end(), op_code, lhs, rhs)

    lhs

// Returns encoded info: prec * 1000 + op_code, or 0 if not infix
fn Parser.infix_op(self: Parser) -> i32:
    let t = self.peek()
    if t == TK_KW_OR: return 1 * 1000 + OP_OR
    if t == TK_KW_AND: return 2 * 1000 + OP_AND
    if t == TK_EQ_EQ: return 3 * 1000 + OP_EQ
    if t == TK_BANG_EQ: return 3 * 1000 + OP_NEQ
    if t == TK_KW_IN: return 3 * 1000 + OP_IN
    if t == TK_KW_NOT:
        if self.pos + 1 < self.tokens.len() and self.tokens.get_tag(self.pos + 1) == TK_KW_IN:
            return 3 * 1000 + OP_NOT_IN
        return 0
    if t == TK_LT: return 4 * 1000 + OP_LT
    if t == TK_GT: return 4 * 1000 + OP_GT
    if t == TK_LT_EQ: return 4 * 1000 + OP_LTE
    if t == TK_GT_EQ: return 4 * 1000 + OP_GTE
    if t == TK_DOT_DOT: return 5 * 1000 + 502
    if t == TK_DOT_DOT_EQ: return 5 * 1000 + 503
    if t == TK_PIPE_GT: return 6 * 1000 + 500
    if t == TK_LT_PIPE: return 6 * 1000 + 501
    if t == TK_LT_LT: return 6 * 1000 + 504
    if t == TK_GT_GT: return 6 * 1000 + 505
    if t == TK_AMPERSAND: return 7 * 1000 + OP_BIT_AND
    if t == TK_CARET: return 8 * 1000 + OP_BIT_XOR
    if t == TK_PIPE: return 9 * 1000 + OP_BIT_OR
    if t == TK_QUESTION_QUESTION: return 10 * 1000 + OP_DEFAULT
    if t == TK_PLUS: return 11 * 1000 + OP_ADD
    if t == TK_PLUS_PLUS: return 11 * 1000 + OP_CONCAT
    if t == TK_MINUS: return 11 * 1000 + OP_SUB
    if t == TK_PLUS_WRAP: return 11 * 1000 + OP_ADD_WRAP
    if t == TK_MINUS_WRAP: return 11 * 1000 + OP_SUB_WRAP
    if t == TK_STAR: return 12 * 1000 + OP_MUL
    if t == TK_SLASH: return 12 * 1000 + OP_DIV
    if t == TK_PERCENT: return 12 * 1000 + OP_MOD
    if t == TK_STAR_WRAP: return 12 * 1000 + OP_MUL_WRAP
    0

// ── Primary expression ──────────────────────────────────────────

fn Parser.parse_primary(self: Parser) -> i32:
    let t = self.peek()
    if t == TK_INT_LIT: return self.parse_int_literal()
    if t == TK_FLOAT_LIT: return self.parse_float_literal()
    if t == TK_STRING_LIT: return self.parse_string_literal()
    if t == TK_C_STRING_LIT: return self.parse_c_string_literal()
    if t == TK_CHAR_LIT: return self.parse_char_literal()
    if t == TK_TRUE or t == TK_FALSE: return self.parse_bool_literal()
    if t == TK_IDENT:
        if self.pos + 1 < self.tokens.len():
            if self.tokens.get_tag(self.pos + 1) == TK_FAT_ARROW:
                return self.parse_fat_arrow_single()
        return self.parse_ident_or_call()
    if t == TK_KW_IT:
        let start = self.current_start()
        let end_pos = self.current_end()
        self.advance()
        if self.implicit_it_depth > 0:
            let err_span = Span { file: self.file_id, start: start, end: end_pos }
            self.diags.emit(Diagnostic.err("nested implicit closure is ambiguous; use explicit parameter for inner closure", err_span))
        self.saw_implicit_it = 1
        self.implicit_it_depth = self.implicit_it_depth + 1
        let sym = self.intern.intern("__it")
        let node = self.pool.add_node(NK_IDENT, start, end_pos, sym, 0, 0)
        return self.parse_postfix(node)
    if t == TK_DOT_IDENT: return self.parse_variant_shorthand()
    if t == TK_L_PAREN: return self.parse_grouped_or_tuple()
    if t == TK_MINUS: return self.parse_unary_negate()
    if t == TK_KW_NOT: return self.parse_unary_not()
    if t == TK_AMPERSAND: return self.parse_ref_of()
    if t == TK_STAR: return self.parse_deref_expr()
    if t == TK_KW_IF: return self.parse_if_expr()
    if t == TK_KW_WHILE: return self.parse_while(0)
    if t == TK_KW_LOOP: return self.parse_loop(0)
    if t == TK_KW_FOR: return self.parse_for(0)
    if t == TK_KW_RETURN: return self.parse_return()
    if t == TK_KW_BREAK: return self.parse_break()
    if t == TK_KW_CONTINUE: return self.parse_continue()
    if t == TK_LABEL: return self.parse_labeled_loop()
    if t == TK_KW_UNSAFE: return self.parse_unsafe()
    if t == TK_KW_DEFER: return self.parse_defer()
    if t == TK_KW_ERRDEFER: return self.parse_errdefer()
    if t == TK_KW_SPAWN: return self.parse_spawn()
    if t == TK_KW_ASYNC: return self.parse_async_expr()
    if t == TK_KW_YIELD: return self.parse_yield()
    if t == TK_KW_COMPTIME: return self.parse_comptime_expr()
    if t == TK_KW_SELECT: return self.parse_select_await()
    if t == TK_L_BRACKET:
        let arr = self.parse_array_literal()
        return self.parse_postfix(arr)
    if t == TK_KW_LET or t == TK_KW_VAR: return self.parse_let_binding()
    if t == TK_KW_CONST: return self.parse_const_binding()
    if t == TK_KW_MATCH: return self.parse_match_expr()
    if t == TK_KW_WITH: return self.parse_with_expr()
    if t == TK_L_BRACE: return self.parse_record_update()
    if t == TK_PIPE:
        self.emit_error("use 'x => body' instead of '|x| body'")
        return 0
    if t == TK_KW_MOVE:
        self.advance()
        // move IDENT => expr
        if self.peek() == TK_IDENT:
            if self.pos + 1 < self.tokens.len():
                if self.tokens.get_tag(self.pos + 1) == TK_FAT_ARROW:
                    let node = self.parse_fat_arrow_single()
                    if node != 0: self.pool.mark_move_closure(node)
                    return node
        // move (params) => expr
        if self.peek() == TK_L_PAREN:
            let save = self.pos
            self.advance()
            self.skip_newlines()
            var is_closure = 0
            if self.peek() == TK_R_PAREN:
                self.advance()
                if self.peek() == TK_FAT_ARROW or self.peek() == TK_ARROW:
                    is_closure = 1
            else:
                is_closure = self.scan_is_paren_closure()
            self.pos = save
            if is_closure == 1:
                let node = self.parse_fat_arrow_paren_closure()
                if node != 0: self.pool.mark_move_closure(node)
                return node
        self.emit_error("'move' must be followed by a closure")
        return 0

    self.emit_error("expected expression")
    0

// ── Literal parsing ─────────────────────────────────────────────

fn Parser.parse_int_literal(self: Parser) -> i32:
    let start = self.current_start()
    let end = self.current_end()
    let text = self.source.slice(start as i64, end as i64)
    self.advance()
    let val = parse_i64(text)
    self.pool.add_node(NK_INT_LIT, start, end, ast_int_part0(val), ast_int_part1(val), ast_int_part2(val))

fn Parser.parse_float_literal(self: Parser) -> i32:
    let start = self.current_start()
    let end = self.current_end()
    let text = self.source.slice(start as i64, end as i64)
    self.advance()
    let str_idx = self.pool.add_string(text)
    self.pool.add_node(NK_FLOAT_LIT, start, end, str_idx, 0, 0)

fn Parser.parse_string_literal(self: Parser) -> i32:
    let start = self.current_start()
    let end = self.current_end()
    let text = self.source.slice(start as i64, end as i64)
    var content = strip_string_token_text(text)
    if is_raw_string_token_text(text):
        content = "\x01raw\x01" ++ content
    let sym = self.intern.intern(content)
    self.advance()
    let node = self.pool.add_node(NK_STRING_LIT, start, end, sym, 0, 0)
    self.parse_postfix(node)

fn Parser.parse_c_string_literal(self: Parser) -> i32:
    let start = self.current_start()
    let end = self.current_end()
    let text = self.source.slice(start as i64, end as i64)
    var raw = ""
    if text.len() >= 3:
        raw = text.slice(2, text.len() as i64 - 1)
    let sym = self.intern.intern(raw)
    self.advance()
    let node = self.pool.add_node(NK_C_STRING_LIT, start, end, sym, 0, 0)
    self.parse_postfix(node)

fn Parser.parse_bool_literal(self: Parser) -> i32:
    let start = self.current_start()
    let end = self.current_end()
    let val = if self.peek() == TK_TRUE: 1 else: 0
    self.advance()
    self.pool.add_node(NK_BOOL_LIT, start, end, val, 0, 0)

fn Parser.parse_char_literal(self: Parser) -> i32:
    let start = self.current_start()
    let end = self.current_end()
    let text = self.source.slice(start as i64, end as i64)
    self.advance()
    // Stage0 parity: char literals lower to integer literals.
    // Supported escapes mirror bootstrap parser behavior.
    var value = 0
    // Support b'X' byte literals as a char-literal token form.
    let base = if text.len() >= 1 and text.byte_at((0) as i64) == 98: 2 else: 1
    if text.len() >= base + 3 and text.byte_at((base) as i64) == 92:  // '\'
        let esc = text.byte_at((base + 1) as i64)
        if esc == 110:  // n
            value = 10
        else if esc == 114:  // r
            value = 13
        else if esc == 116:  // t
            value = 9
        else if esc == 48:  // 0
            value = 0
        else if esc == 120 and text.len() >= base + 4:  // xNN
            let hi = hex_digit_value(text.byte_at((base + 2) as i64))
            let lo = if text.len() >= base + 5: hex_digit_value(text.byte_at((base + 3) as i64)) else: -1
            if hi >= 0 and lo >= 0:
                value = hi * 16 + lo
            else:
                value = 0
        else if esc == 92:  // \
            value = 92
        else if esc == 39:  // '
            value = 39
        else if esc == 34:  // "
            value = 34
        else:
            value = esc as i32
    else if text.len() >= base + 2:
        value = text.byte_at((base) as i64) as i32
    let value64 = value as i64
    self.pool.add_node(NK_INT_LIT, start, end, ast_int_part0(value64), ast_int_part1(value64), ast_int_part2(value64))

fn strip_string_token_text(text: str) -> str:
    if text.len() >= 2 and text.byte_at((0) as i64) == 114:  // r
        var i = 1
        while i < text.len() as i32 and text.byte_at((i) as i64) == 35:  // #
            i = i + 1
        if i < text.len() as i32 and text.byte_at((i) as i64) == 34:  // opening "
            let content_start = i + 1
            var end_q = text.len() as i32 - 1
            while end_q >= content_start and text.byte_at((end_q) as i64) == 35:
                end_q = end_q - 1
            if end_q >= content_start and text.byte_at((end_q) as i64) == 34:
                return text.slice(content_start as i64, end_q as i64)

    if text.len() >= 6 and text.slice(0, 3) == "\"\"\"":
        var content = text.slice(3, text.len() as i64 - 3)
        if content.len() > 0 and content.byte_at((0) as i64) == 10:
            content = content.slice(1, content.len())
        if content.len() > 0 and content.byte_at((content.len() as i32 - 1) as i64) == 10:
            content = content.slice(0, content.len() - 1)
        return dedent_multiline(content)

    if text.len() >= 2:
        return text.slice(1, text.len() as i64 - 1)
    ""

fn is_raw_string_token_text(text: str) -> bool:
    if text.len() < 3:
        return false
    if text.byte_at((0) as i64) != 114:  // r
        return false
    var i = 1
    while i < text.len() as i32 and text.byte_at((i) as i64) == 35:  // #
        i = i + 1
    if i < text.len() as i32 and text.byte_at((i) as i64) == 34:  // "
        return true
    false

fn dedent_multiline(text: str) -> str:
    let len = text.len() as i32
    var min_indent = 0 - 1
    var line_start = 0
    var i = 0
    while i <= len:
        if i == len or text.byte_at((i) as i64) == 10:
            var j = line_start
            while j < i and (text.byte_at((j) as i64) == 32 or text.byte_at((j) as i64) == 9):
                j = j + 1
            var has_non_ws = 0
            var k = j
            while k < i:
                if text.byte_at((k) as i64) != 32 and text.byte_at((k) as i64) != 9:
                    has_non_ws = 1
                k = k + 1
            if has_non_ws != 0:
                let indent = j - line_start
                if min_indent < 0 or indent < min_indent:
                    min_indent = indent
            line_start = i + 1
        i = i + 1

    if min_indent <= 0:
        return text

    var out = ""
    line_start = 0
    i = 0
    while i <= len:
        if i == len or text.byte_at((i) as i64) == 10:
            var cut = min_indent
            var j = line_start
            while cut > 0 and j < i and (text.byte_at((j) as i64) == 32 or text.byte_at((j) as i64) == 9):
                j = j + 1
                cut = cut - 1
            out = out ++ text.slice(j as i64, i as i64)
            if i != len:
                out = out ++ "\n"
            line_start = i + 1
        i = i + 1
    out

fn hex_digit_value(ch: i32) -> i32:
    if ch >= 48 and ch <= 57:
        return ch - 48
    if ch >= 97 and ch <= 102:
        return ch - 87
    if ch >= 65 and ch <= 70:
        return ch - 55
    0 - 1

fn Parser.parse_ident_or_call(self: Parser) -> i32:
    let start = self.current_start()
    let end = self.current_end()
    let sym = self.intern_current()
    self.advance()
    let node = self.pool.add_node(NK_IDENT, start, end, sym, 0, 0)
    self.parse_postfix(node)

// ── Postfix parsing ──────────────────────────────────────────────

fn Parser.parse_postfix(self: Parser, lhs_in: i32) -> i32:
    var lhs = lhs_in
    while true:
        let t = self.peek()
        if t == TK_L_PAREN:
            lhs = self.parse_call(lhs)
        else if t == TK_DOT:
            lhs = self.parse_dot(lhs)
        else if t == TK_DOT_IDENT:
            // Type.Variant — treat dot-ident as field access when postfix
            let start = self.current_start()
            let end = self.current_end()
            let text = self.source.slice((start + 1) as i64, end as i64)
            let field = self.intern.intern(text)
            self.advance()
            lhs = self.pool.add_node(NK_FIELD_ACCESS, self.pool.get_start(lhs), end, lhs, field, 0)
        else if t == TK_L_BRACE:
            // Struct literal only when lhs is an identifier
            if self.pool.kind(lhs) != NK_IDENT:
                return lhs
            lhs = self.parse_struct_literal(lhs)
        else if t == TK_L_BRACKET:
            lhs = self.parse_index_or_slice(lhs)
        else if t == TK_KW_AS:
            if self.suppress_as != 0:
                return lhs
            self.advance()
            let target_type = self.parse_type_expr()
            lhs = self.pool.add_node(NK_CAST, self.pool.get_start(lhs), self.prev_end(), lhs, target_type, 0)
        else if t == TK_QUESTION:
            let qend = self.current_end()
            self.advance()
            lhs = self.pool.add_node(NK_UNARY, self.pool.get_start(lhs), qend, UOP_TRY, lhs, 0)
        else if t == TK_QUESTION_DOT:
            lhs = self.parse_optional_chain(lhs)
        else:
            return lhs
    lhs

fn Parser.maybe_wrap_implicit_it(self: Parser, expr: i32) -> i32:
    let it_sym = self.intern.intern("__it")
    let param_start = self.pool.extra_len()
    self.pool.add_extra(it_sym)
    self.pool.add_extra(0)
    self.pool.add_node(NK_CLOSURE, self.pool.get_start(expr), self.pool.get_end(expr), expr, param_start, 1)

fn Parser.parse_call(self: Parser, callee: i32) -> i32:
    self.advance()  // consume (
    self.skip_newlines()
    var args: Vec[i32] = Vec.new()
    if self.peek() != TK_R_PAREN:
        while self.peek() != TK_R_PAREN and self.peek() != TK_EOF:
            let outer_it = self.saw_implicit_it
            let outer_depth = self.implicit_it_depth
            self.saw_implicit_it = 0
            var arg = self.parse_expr()
            if self.saw_implicit_it == 1:
                self.implicit_it_depth = self.implicit_it_depth - 1
                arg = self.maybe_wrap_implicit_it(arg)
            self.saw_implicit_it = outer_it
            self.implicit_it_depth = outer_depth
            args.push(arg)
            self.skip_newlines()
            if self.peek() != TK_COMMA:
                break
            self.advance()
            self.skip_newlines()
            if self.peek() == TK_R_PAREN:
                break
    self.skip_newlines()
    self.expect(TK_R_PAREN)
    let arg_count = args.len() as i32
    var placeholder_count = 0
    for ai in 0..arg_count:
        let arg = args.get(ai as i64)
        if self.pool.kind(arg) == NK_IDENT:
            let sym = self.pool.get_data0(arg)
            if self.intern.resolve(sym) == "_":
                placeholder_count = placeholder_count + 1

    let extra_start = self.pool.extra_len()
    var partial_param_syms: Vec[i32] = Vec.new()
    for ai in 0..arg_count:
        let arg = args.get(ai as i64)
        if self.pool.kind(arg) == NK_IDENT:
            let sym = self.pool.get_data0(arg)
            if self.intern.resolve(sym) == "_":
                let pname = "__partial_arg_" ++ int_to_string(self.pos) ++ "_" ++ int_to_string(partial_param_syms.len() as i32)
                let psym = self.intern.intern(pname)
                partial_param_syms.push(psym)
                let pnode = self.pool.add_node(NK_IDENT, self.pool.get_start(arg), self.pool.get_end(arg), psym, 0, 0)
                self.pool.add_extra(pnode)
                continue
        self.pool.add_extra(arg)
    let call_node = self.pool.add_node(NK_CALL, self.pool.get_start(callee), self.prev_end(), callee, extra_start, arg_count)

    if placeholder_count == 0:
        return call_node

    let param_start = self.pool.extra_len()
    let param_count = partial_param_syms.len() as i32
    for pi in 0..param_count:
        self.pool.add_extra(partial_param_syms.get(pi as i64))
        self.pool.add_extra(0)
    self.pool.add_node(NK_CLOSURE, self.pool.get_start(callee), self.prev_end(), call_node, param_start, param_count)

fn Parser.parse_dot(self: Parser, lhs: i32) -> i32:
    self.advance()  // consume .
    // .await
    if self.peek() == TK_KW_AWAIT:
        self.advance()
        return self.pool.add_node(NK_AWAIT, self.pool.get_start(lhs), self.prev_end(), lhs, 0, 0)
    // Tuple field .0 .1
    if self.peek() == TK_INT_LIT:
        let field = self.intern_current()
        self.advance()
        return self.pool.add_node(NK_FIELD_ACCESS, self.pool.get_start(lhs), self.prev_end(), lhs, field, 0)
    let field = self.expect_ident_or_keyword()
    self.pool.add_node(NK_FIELD_ACCESS, self.pool.get_start(lhs), self.prev_end(), lhs, field, 0)

fn Parser.build_composed_closure(self: Parser, lhs_fn: i32, rhs_fn: i32, is_forward: i32) -> i32:
    let param_name = "__pipe_arg_" ++ int_to_string(self.pos)
    let param_sym = self.intern.intern(param_name)
    let param_expr = self.pool.add_node(
        NK_IDENT,
        self.pool.get_start(lhs_fn),
        self.pool.get_end(lhs_fn),
        param_sym,
        0,
        0,
    )

    let first_callee = if is_forward != 0: lhs_fn else: rhs_fn
    let second_callee = if is_forward != 0: rhs_fn else: lhs_fn

    let first_args = self.pool.extra_len()
    self.pool.add_extra(param_expr)
    let first_call = self.pool.add_node(
        NK_CALL,
        self.pool.get_start(lhs_fn),
        self.pool.get_end(rhs_fn),
        first_callee,
        first_args,
        1,
    )

    let second_args = self.pool.extra_len()
    self.pool.add_extra(first_call)
    let second_call = self.pool.add_node(
        NK_CALL,
        self.pool.get_start(lhs_fn),
        self.pool.get_end(rhs_fn),
        second_callee,
        second_args,
        1,
    )

    // NK_CLOSURE expects [name, type] pairs.
    let params_start = self.pool.extra_len()
    self.pool.add_extra(param_sym)
    self.pool.add_extra(0)
    self.pool.add_node(
        NK_CLOSURE,
        self.pool.get_start(lhs_fn),
        self.pool.get_end(second_call),
        second_call,
        params_start,
        1,
    )

fn Parser.parse_struct_literal(self: Parser, lhs: i32) -> i32:
    let struct_name = self.pool.get_data0(lhs)
    self.advance()  // consume {
    self.skip_newlines()
    var fields: Vec[i32] = Vec.new()
    var field_count = 0
    while self.peek() != TK_R_BRACE and self.peek() != TK_EOF:
        let fname = self.expect_ident()
        if self.peek() == TK_COLON:
            self.advance()
            self.skip_newlines()
            let val = self.parse_expr()
            fields.push(fname)
            fields.push(val)
        else:
            // Shorthand: name means name: name
            let ident_node = self.pool.add_node(NK_IDENT, self.pool.get_start(lhs), self.prev_end(), fname, 0, 0)
            fields.push(fname)
            fields.push(ident_node)
        field_count = field_count + 1
        self.skip_newlines()
        if self.peek() == TK_COMMA:
            self.advance()
            self.skip_newlines()
    self.expect(TK_R_BRACE)
    let extra_start = self.pool.extra_len()
    for fi in 0..fields.len() as i32:
        self.pool.add_extra(fields.get(fi as i64))
    self.pool.add_node(NK_STRUCT_LIT, self.pool.get_start(lhs), self.prev_end(), struct_name, extra_start, field_count)

fn Parser.parse_index_or_slice(self: Parser, lhs: i32) -> i32:
    self.advance()  // consume [
    let index = self.parse_index_expr()
    if self.peek() == TK_DOT_DOT:
        self.advance()
        var end_expr = 0
        if self.peek() != TK_R_BRACKET:
            end_expr = self.parse_expr()
        self.expect(TK_R_BRACKET)
        return self.pool.add_node(NK_SLICE, self.pool.get_start(lhs), self.prev_end(), lhs, index, end_expr)
    // Support two-arg subscript for HashMap[K, V].new() syntax
    var second = 0
    if self.peek() == TK_COMMA:
        self.advance()
        second = self.parse_index_expr()
    self.expect(TK_R_BRACKET)
    self.pool.add_node(NK_INDEX, self.pool.get_start(lhs), self.prev_end(), lhs, index, second)

fn Parser.parse_index_expr(self: Parser) -> i32:
    self.parse_precedence(6)

fn Parser.parse_optional_chain(self: Parser, lhs: i32) -> i32:
    self.advance()  // consume ?.
    var member = 0
    if self.peek() == TK_INT_LIT:
        member = self.intern_current()
        self.advance()
    else:
        member = self.expect_ident()
    var args: Vec[i32] = Vec.new()
    if self.peek() == TK_L_PAREN:
        self.advance()
        self.skip_newlines()
        while self.peek() != TK_R_PAREN and self.peek() != TK_EOF:
            args.push(self.parse_expr())
            self.skip_newlines()
            if self.peek() == TK_COMMA:
                self.advance()
                self.skip_newlines()
        self.expect(TK_R_PAREN)
    let extra_start = self.pool.extra_len()
    let arg_count = args.len() as i32
    self.pool.add_extra(arg_count)
    for ai in 0..arg_count:
        self.pool.add_extra(args.get(ai as i64))
    self.pool.add_node(NK_OPTIONAL_CHAIN, self.pool.get_start(lhs), self.prev_end(), lhs, member, extra_start)

// ── Variant shorthand ────────────────────────────────────────────

fn Parser.parse_variant_shorthand(self: Parser) -> i32:
    let start = self.current_start()
    let end = self.current_end()
    let text = self.source.slice((start + 1) as i64, end as i64)
    let sym = self.intern.intern(text)
    self.advance()
    var args: Vec[i32] = Vec.new()
    if self.peek() == TK_L_PAREN:
        self.advance()
        self.skip_newlines()
        while self.peek() != TK_R_PAREN and self.peek() != TK_EOF:
            args.push(self.parse_expr())
            if self.peek() == TK_COMMA:
                self.advance()
                self.skip_newlines()
        self.skip_newlines()
        self.expect(TK_R_PAREN)
    let extra_start = self.pool.extra_len()
    let arg_count = args.len() as i32
    for ai in 0..arg_count:
        self.pool.add_extra(args.get(ai as i64))
    self.pool.add_node(NK_VARIANT_SHORTHAND, start, self.prev_end(), sym, extra_start, arg_count)

// ── Grouped / tuple ──────────────────────────────────────────────

fn Parser.parse_grouped_or_tuple(self: Parser) -> i32:
    let start = self.current_start()
    let open_paren_pos = self.pos
    self.advance()  // consume (
    self.skip_newlines()

    if self.peek() == TK_R_PAREN:
        let end = self.current_end()
        self.advance()
        // () => expr or () -> Type => expr is a zero-param closure
        if self.peek() == TK_FAT_ARROW or self.peek() == TK_ARROW:
            self.pos = open_paren_pos
            return self.parse_fat_arrow_paren_closure()
        let node = self.pool.add_node(NK_TUPLE, start, end, self.pool.extra_len(), 0, 0)
        return self.parse_postfix(node)

    // Check if (params) => closure
    if self.scan_is_paren_closure() == 1:
        self.pos = open_paren_pos
        return self.parse_fat_arrow_paren_closure()

    let first = self.parse_expr()
    if self.peek() == TK_COMMA:
        var elems: Vec[i32] = Vec.new()
        elems.push(first)
        while self.peek() == TK_COMMA:
            self.advance()
            self.skip_newlines()
            if self.peek() == TK_R_PAREN:
                break
            let elem = self.parse_expr()
            elems.push(elem)
        self.expect(TK_R_PAREN)
        let extra_start = self.pool.extra_len()
        for ei in 0..elems.len() as i32:
            self.pool.add_extra(elems.get(ei as i64))
        let count = elems.len() as i32
        let node = self.pool.add_node(NK_TUPLE, start, self.prev_end(), extra_start, count, 0)
        return self.parse_postfix(node)

    self.expect(TK_R_PAREN)
    let node = self.pool.add_node(NK_GROUPED, start, self.prev_end(), first, 0, 0)
    self.parse_postfix(node)

// ── Unary expressions ────────────────────────────────────────────

fn Parser.parse_unary_negate(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    if self.peek() == TK_INT_LIT:
        let end = self.current_end()
        let text = self.source.slice(start as i64 + 1, end as i64)
        let value = 0 - parse_i64(text)
        self.advance()
        return self.pool.add_node(NK_INT_LIT, start, end, ast_int_part0(value), ast_int_part1(value), ast_int_part2(value))
    let operand = self.parse_primary()
    self.pool.add_node(NK_UNARY, start, self.prev_end(), UOP_NEGATE, operand, 0)

fn Parser.parse_unary_not(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    let operand = self.parse_primary()
    self.pool.add_node(NK_UNARY, start, self.prev_end(), UOP_NOT, operand, 0)

fn Parser.parse_ref_of(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    var op = UOP_REF
    if self.peek() == TK_KW_MUT:
        op = UOP_MUT_REF
        self.advance()
    let operand = self.parse_primary()
    self.pool.add_node(NK_UNARY, start, self.prev_end(), op, operand, 0)

fn Parser.parse_deref_expr(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    let operand = self.parse_primary()
    self.pool.add_node(NK_UNARY, start, self.prev_end(), UOP_DEREF, operand, 0)

// ── Control flow expressions ─────────────────────────────────────

// Returns 1 if the token at `pos` is the first non-whitespace on its line.
fn is_first_on_line(source: str, pos: i32) -> i32:
    var p = pos - 1
    while p >= 0:
        let ch = source.byte_at(p as i64)
        if ch == 10:
            return 1
        if ch != 32 and ch != 9:
            return 0
        p = p - 1
    1

fn Parser.parse_if_expr(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()  // consume if
    self.skip_newlines()

    if self.peek() == TK_KW_LET:
        return self.parse_if_let(start)

    let cond = self.parse_expr()
    var use_block = false
    if self.peek() == TK_KW_THEN:
        self.advance()
        self.skip_newlines()
    else if self.peek() == TK_COLON:
        self.advance()
        use_block = true
    else:
        self.skip_newlines()

    let if_col = column_of(self.source, start)
    // Dangling-else resolution: for block-form if that starts a new line,
    // only accept else at the same column. This prevents a nested if from
    // stealing an outer if's else. Inline ifs and else-if chains are exempt.
    let is_stmt_if = use_block and is_first_on_line(self.source, start) != 0
    let then_body = if use_block: self.parse_block_or_expr() else: self.parse_expr()
    var else_body = 0
    let save = self.pos
    self.skip_newlines()
    let crossed_newline = self.pos != save
    if self.peek() == TK_KW_ELSE:
        let else_col = column_of(self.source, self.current_start())
        if crossed_newline and is_stmt_if and else_col != if_col:
            self.pos = save
        else:
            self.advance()
            if self.peek() == TK_COLON:
                self.advance()
            else_body = self.parse_block_or_expr()
    else:
        self.pos = save

    self.pool.add_node(NK_IF_EXPR, start, self.prev_end(), cond, then_body, else_body)

fn Parser.parse_if_let(self: Parser, start: i32) -> i32:
    self.advance()  // consume first 'let'
    let pat = self.parse_pattern()
    if self.expect(TK_EQ) == 0:
        return 0
    let subject = self.parse_expr()

    // Store clauses as flat triples: (kind, data0, data1).
    // kind=0 → let clause (data0=pattern, data1=subject)
    // kind=1 → cond clause (data0=cond_expr, data1=0)
    var clauses: Vec[i32] = Vec.new()
    clauses.push(0)
    clauses.push(pat)
    clauses.push(subject)

    // Chained form: `if let A = x, let B = y, cond, ...`
    while self.peek() == TK_COMMA:
        self.advance()
        self.skip_newlines()
        if self.peek() == TK_KW_LET:
            self.advance()  // consume 'let'
            let p = self.parse_pattern()
            if self.expect(TK_EQ) == 0:
                return 0
            let s = self.parse_expr()
            clauses.push(0)
            clauses.push(p)
            clauses.push(s)
        else:
            let cond = self.parse_expr()
            clauses.push(1)
            clauses.push(cond)
            clauses.push(0)

    var use_block = false
    if self.peek() == TK_KW_THEN:
        self.advance()
        self.skip_newlines()
    else if self.peek() == TK_COLON:
        self.advance()
        use_block = true
    else:
        self.skip_newlines()

    let if_col = column_of(self.source, start)
    let is_stmt_if = use_block and is_first_on_line(self.source, start) != 0
    let then_body = if use_block: self.parse_block_or_expr() else: self.parse_expr()

    var else_body = 0
    let save = self.pos
    self.skip_newlines()
    let crossed_newline = self.pos != save
    if self.peek() == TK_KW_ELSE:
        let else_col = column_of(self.source, self.current_start())
        if crossed_newline and is_stmt_if and else_col != if_col:
            self.pos = save
        else:
            self.advance()
            if self.peek() == TK_COLON:
                self.advance()
            else_body = self.parse_block_or_expr()
    else:
        self.pos = save
    if else_body == 0:
        else_body = self.pool.add_node(NK_INT_LIT, start, start, 0, 0, 0)

    // Desugar chained if-let into nested match/if expressions from right to left.
    var acc = then_body
    let clause_count = clauses.len() as i32 / 3
    var ci = clause_count - 1
    while ci >= 0:
        let kind = clauses.get((ci * 3) as i64)
        let d0 = clauses.get((ci * 3 + 1) as i64)
        let d1 = clauses.get((ci * 3 + 2) as i64)
        if kind == 0:
            // Let clause → match d1 { d0 -> acc, _ -> else_body }
            let extra_start = self.pool.extra_len()
            let arm1 = self.pool.add_node(NK_MATCH_ARM, start, self.prev_end(), d0, acc, 0)
            self.pool.add_extra(arm1)
            let wildcard = self.pool.add_node(NK_PAT_WILDCARD, start, start, 0, 0, 0)
            let arm2 = self.pool.add_node(NK_MATCH_ARM, start, self.prev_end(), wildcard, else_body, 0)
            self.pool.add_extra(arm2)
            acc = self.pool.add_node(NK_MATCH, start, self.prev_end(), d1, extra_start, 2)
        else:
            // Cond clause → if d0 then acc else else_body
            acc = self.pool.add_node(NK_IF_EXPR, start, self.prev_end(), d0, acc, else_body)
        ci = ci - 1
    acc

fn Parser.parse_return(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    var value = 0
    let t = self.peek()
    if t != TK_NEWLINE and t != TK_EOF and t != TK_R_PAREN and t != TK_R_BRACE:
        value = self.parse_expr()
    self.pool.add_node(NK_RETURN, start, self.prev_end(), value, 0, 0)

fn Parser.parse_defer(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    let body = self.parse_expr()
    self.pool.add_node(NK_DEFER, start, self.prev_end(), body, 0, 0)

fn Parser.parse_errdefer(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    let body = self.parse_expr()
    self.pool.add_node(NK_ERRDEFER, start, self.prev_end(), body, 0, 0)

fn Parser.parse_unsafe(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    if self.peek() == TK_COLON:
        self.advance()
    self.parse_block_or_expr()

fn Parser.parse_yield(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    let value = self.parse_expr()
    self.pool.add_node(NK_YIELD, start, self.prev_end(), value, 0, 0)

fn Parser.parse_comptime_expr(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    let inner = self.parse_expr()
    self.pool.add_node(NK_COMPTIME, start, self.prev_end(), inner, 0, 0)

fn Parser.parse_spawn(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    let value = self.parse_expr()
    self.pool.add_node(NK_SPAWN, start, self.prev_end(), value, 0, 0)

fn Parser.parse_async_expr(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    if self.is_ident_named("scope"):
        self.advance()
        var scope_name = self.intern.intern("s")
        if self.peek() == TK_PIPE:
            self.advance()
            if self.peek() == TK_IDENT:
                scope_name = self.expect_ident()
            self.expect(TK_PIPE)
        if self.peek() == TK_COLON:
            self.advance()
        let body = self.parse_block_or_expr()
        return self.pool.add_node(NK_ASYNC_SCOPE, start, self.prev_end(), scope_name, body, 0)

    if self.peek() == TK_COLON:
        self.advance()
    let body = self.parse_block_or_expr()
    self.pool.add_node(NK_ASYNC_BLOCK, start, self.prev_end(), body, 0, 0)

fn Parser.parse_select_await(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()  // consume select
    self.expect(TK_KW_AWAIT)
    if self.peek() == TK_COLON:
        self.advance()
    self.skip_newlines()

    var arm_entries: Vec[i32] = Vec.new()
    var arm_count = 0
    var arm_col = -1

    while self.peek() != TK_EOF:
        if self.peek() != TK_IDENT:
            break
        let cur_col = column_of(self.source, self.current_start())
        if arm_col >= 0 and cur_col != arm_col:
            break
        if arm_col < 0:
            arm_col = cur_col
        if self.pos + 1 < self.tokens.len() and self.tokens.get_tag(self.pos + 1) != TK_EQ:
            break
        let name_sym = self.expect_ident()
        if self.peek() != TK_EQ:
            break
        self.advance()
        self.skip_newlines()
        let task_expr = self.parse_expr()
        self.expect(TK_FAT_ARROW)
        let body = self.parse_block_or_expr()
        arm_entries.push(name_sym)
        arm_entries.push(task_expr)
        arm_entries.push(body)
        arm_count = arm_count + 1

        let save = self.pos
        self.skip_newlines()
        if self.peek() == TK_IDENT and self.pos + 1 < self.tokens.len() and self.tokens.get_tag(self.pos + 1) == TK_EQ:
            let next_col = column_of(self.source, self.current_start())
            if arm_col >= 0 and next_col == arm_col:
                continue
        self.pos = save
        break

    let extra_start = self.pool.extra_len()
    for ei in 0..arm_entries.len() as i32:
        self.pool.add_extra(arm_entries.get(ei as i64))
    self.pool.add_node(NK_SELECT_AWAIT, start, self.prev_end(), extra_start, arm_count, 0)

// ── Loop expressions ─────────────────────────────────────────────

fn Parser.parse_while(self: Parser, label: i32) -> i32:
    let start = self.current_start()
    self.advance()
    self.skip_newlines()

    if self.peek() == TK_KW_LET:
        return self.parse_while_let(start)

    let cond = self.parse_expr()
    if self.peek() == TK_COLON:
        self.advance()
    let body = self.parse_block_or_expr()
    self.pool.add_node(NK_WHILE, start, self.prev_end(), cond, body, label)

fn Parser.parse_while_let(self: Parser, start: i32) -> i32:
    self.advance()  // consume let
    let pat = self.parse_pattern()
    if self.expect(TK_EQ) == 0:
        return 0
    let subject = self.parse_expr()
    if self.peek() == TK_COLON:
        self.advance()
    let body = self.parse_block_or_expr()

    // Desugar to: loop: match subject { pat -> body, _ -> break }
    let break_node = self.pool.add_node(NK_BREAK, start, start, 0, 0, 0)
    let extra_start = self.pool.extra_len()
    let arm1 = self.pool.add_node(NK_MATCH_ARM, start, self.prev_end(), pat, body, 0)
    self.pool.add_extra(arm1)
    let wildcard = self.pool.add_node(NK_PAT_WILDCARD, start, start, 0, 0, 0)
    let arm2 = self.pool.add_node(NK_MATCH_ARM, start, self.prev_end(), wildcard, break_node, 0)
    self.pool.add_extra(arm2)
    let match_node = self.pool.add_node(NK_MATCH, start, self.prev_end(), subject, extra_start, 2)
    self.pool.add_node(NK_LOOP, start, self.prev_end(), match_node, 0, 0)

fn Parser.parse_loop(self: Parser, label: i32) -> i32:
    let start = self.current_start()
    self.advance()
    if self.peek() == TK_COLON:
        self.advance()
    let body = self.parse_block_or_expr()
    self.pool.add_node(NK_LOOP, start, self.prev_end(), body, label, 0)

fn Parser.parse_for(self: Parser, label: i32) -> i32:
    let start = self.current_start()
    self.advance()
    self.skip_newlines()
    var binding = 0
    var index_binding = 0

    if self.peek() == TK_L_PAREN:
        // Tuple destructuring - simplified: parse as pattern
        let pat = self.parse_pattern()
        binding = pat
    else:
        binding = self.expect_ident()
        if self.peek() == TK_COMMA:
            self.advance()
            index_binding = self.expect_ident()

    if self.expect(TK_KW_IN) == 0:
        return 0
    self.skip_newlines()
    let iterable = self.parse_expr()
    if self.peek() == TK_COLON:
        self.advance()
    let body = self.parse_block_or_expr()

    let for_node = self.pool.add_node(NK_FOR, start, self.prev_end(), binding, iterable, body)
    self.pool.add_for_meta(for_node, index_binding, label)
    for_node

fn Parser.parse_labeled_loop(self: Parser) -> i32:
    let start = self.current_start()
    let label_end = self.current_end()
    let label_text = self.source.slice((start + 1) as i64, label_end as i64)
    let label_sym = self.intern.intern(label_text)
    self.advance()

    if self.peek() != TK_COLON:
        self.emit_error("expected ':' after loop label")
        return 0
    self.advance()
    self.skip_newlines()

    let t = self.peek()
    if t == TK_KW_FOR: return self.parse_for(label_sym)
    if t == TK_KW_WHILE: return self.parse_while(label_sym)
    if t == TK_KW_LOOP: return self.parse_loop(label_sym)
    self.emit_error("expected 'for', 'while', or 'loop' after label")
    0

fn Parser.parse_break(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    var label = 0
    if self.peek() == TK_LABEL:
        let ls = self.current_start()
        let le = self.current_end()
        label = self.intern.intern(self.source.slice((ls + 1) as i64, le as i64))
        self.advance()
    var value = 0
    let t = self.peek()
    if t != TK_NEWLINE and t != TK_EOF and t != TK_R_BRACE and t != TK_R_PAREN and t != TK_R_BRACKET:
        value = self.parse_expr()
    self.pool.add_node(NK_BREAK, start, self.prev_end(), value, label, 0)

fn Parser.parse_continue(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    var label = 0
    if self.peek() == TK_LABEL:
        let ls = self.current_start()
        let le = self.current_end()
        label = self.intern.intern(self.source.slice((ls + 1) as i64, le as i64))
        self.advance()
    self.pool.add_node(NK_CONTINUE, start, self.prev_end(), label, 0, 0)

// ── Match expression ─────────────────────────────────────────────

fn Parser.parse_match_expr(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    self.skip_newlines()
    let subject = self.parse_expr()
    self.skip_newlines()
    let arm_count = self.parse_match_arms()
    let extra_start = if arm_count > 0: self.pool.extra_len() - arm_count else: self.pool.extra_len()
    self.pool.add_node(NK_MATCH, start, self.prev_end(), subject, extra_start, arm_count)

fn Parser.parse_match_arms(self: Parser) -> i32:
    var arms: Vec[i32] = Vec.new()
    var arm_col = -1

    while self.peek() != TK_EOF:
        let t = self.peek()
        if not self.is_arm_token(t):
            break

        let cur_col = column_of(self.source, self.current_start())
        if arm_col >= 0 and cur_col != arm_col:
            break
        if arm_col < 0:
            arm_col = cur_col

        let arm_start = self.current_start()
        var pattern = self.parse_pattern()

        // Or-pattern: A | B | C
        if self.peek() == TK_PIPE:
            let or_start = self.pool.extra_len()
            self.pool.add_extra(pattern)
            var or_count = 1
            while self.peek() == TK_PIPE:
                self.advance()
                self.skip_newlines()
                let alt = self.parse_pattern()
                self.pool.add_extra(alt)
                or_count = or_count + 1
            pattern = self.pool.add_node(NK_PAT_OR, arm_start, self.prev_end(), or_start, or_count, 0)

        // Guard clause
        var guard = 0
        if self.peek() == TK_KW_IF:
            self.advance()
            guard = self.parse_expr()

        if self.expect(TK_FAT_ARROW) == 0:
            break
        self.skip_newlines()
        let body = self.parse_block_or_expr()

        let arm = self.pool.add_node(NK_MATCH_ARM, arm_start, self.prev_end(), pattern, body, guard)
        arms.push(arm)

        let save = self.pos
        self.skip_newlines()
        if self.peek() == TK_EOF:
            break
        if not self.is_arm_token(self.peek()):
            self.pos = save
            break
        let next_col = column_of(self.source, self.current_start())
        if arm_col >= 0 and next_col != arm_col:
            self.pos = save
            break

    let arm_count = arms.len() as i32
    for ai in 0..arm_count:
        self.pool.add_extra(arms.get(ai as i64))
    arm_count

fn Parser.is_arm_token(self: Parser, t: i32) -> bool:
    t == TK_IDENT or t == TK_INT_LIT or t == TK_DOT_IDENT or t == TK_TRUE or t == TK_FALSE or t == TK_STRING_LIT or t == TK_MINUS or t == TK_L_BRACKET or t == TK_L_PAREN or t == TK_L_BRACE

// ── Pattern parsing ──────────────────────────────────────────────

fn Parser.parse_pattern(self: Parser) -> i32:
    let start = self.current_start()
    let end = self.current_end()
    let t = self.peek()

    if t == TK_INT_LIT:
        let text = self.source.slice(start as i64, end as i64)
        self.advance()
        let val = parse_int(text)
        // Range pattern
        if self.peek() == TK_DOT_DOT or self.peek() == TK_DOT_DOT_EQ:
            let inclusive = if self.peek() == TK_DOT_DOT_EQ: 1 else: 0
            self.advance()
            let es = self.current_start()
            let ee = self.current_end()
            let etext = self.source.slice(es as i64, ee as i64)
            self.expect(TK_INT_LIT)
            let eval = parse_int(etext)
            return self.pool.add_node(NK_PAT_RANGE, start, self.prev_end(), val, eval, inclusive)
        return self.pool.add_node(NK_PAT_INT, start, end, val, 0, 0)

    if t == TK_TRUE:
        self.advance()
        return self.pool.add_node(NK_PAT_BOOL, start, end, 1, 0, 0)
    if t == TK_FALSE:
        self.advance()
        return self.pool.add_node(NK_PAT_BOOL, start, end, 0, 0, 0)
    if t == TK_STRING_LIT:
        let raw = self.source.slice((start + 1) as i64, (end - 1) as i64)
        let sym = self.intern.intern(raw)
        self.advance()
        return self.pool.add_node(NK_PAT_STRING, start, end, sym, 0, 0)
    if t == TK_MINUS:
        self.advance()
        let ns = self.current_start()
        let ne = self.current_end()
        let text = self.source.slice(ns as i64, ne as i64)
        self.expect(TK_INT_LIT)
        let val = 0 - parse_int(text)
        // Check for range pattern after negative number
        if self.peek() == TK_DOT_DOT or self.peek() == TK_DOT_DOT_EQ:
            let inclusive = if self.peek() == TK_DOT_DOT_EQ: 1 else: 0
            self.advance()
            // Parse range end (may also be negative)
            var eval = 0
            if self.peek() == TK_MINUS:
                self.advance()
                let es = self.current_start()
                let ee = self.current_end()
                let etext = self.source.slice(es as i64, ee as i64)
                self.expect(TK_INT_LIT)
                eval = 0 - parse_int(etext)
            else:
                let es = self.current_start()
                let ee = self.current_end()
                let etext = self.source.slice(es as i64, ee as i64)
                self.expect(TK_INT_LIT)
                eval = parse_int(etext)
            return self.pool.add_node(NK_PAT_RANGE, start, self.prev_end(), val, eval, inclusive)
        return self.pool.add_node(NK_PAT_INT, start, self.prev_end(), val, 0, 0)

    if t == TK_IDENT:
        let name = self.expect_ident()
        let name_str = self.intern.resolve(name)
        if name_str == "_":
            return self.pool.add_node(NK_PAT_WILDCARD, start, self.prev_end(), 0, 0, 0)
        // Variant with payload
        if self.peek() == TK_L_PAREN:
            self.advance()
            let extra_start = self.pool.extra_len()
            var binding_count = 0
            while self.peek() != TK_R_PAREN and self.peek() != TK_EOF:
                let inner = self.parse_pattern()
                self.pool.add_extra(inner)
                binding_count = binding_count + 1
                if self.peek() == TK_COMMA:
                    self.advance()
                    self.skip_newlines()
            self.expect(TK_R_PAREN)
            return self.pool.add_node(NK_PAT_VARIANT, start, self.prev_end(), name, extra_start, binding_count)
        // Uppercase = unit variant
        if name_str.len() > 0 and name_str.byte_at((0) as i64) >= 65 and name_str.byte_at((0) as i64) <= 90:
            if self.peek() == TK_L_BRACE:
                return self.parse_struct_pattern(name, start)
            return self.pool.add_node(NK_PAT_VARIANT, start, self.prev_end(), name, 0, 0)
        // At-binding
        if self.peek() == TK_AT:
            self.advance()
            let inner = self.parse_pattern()
            return self.pool.add_node(NK_PAT_AT_BINDING, start, self.prev_end(), name, inner, 0)
        // Typed binding: ident: Type (for dyn trait matching)
        if self.peek() == TK_COLON:
            self.advance()
            let type_sym = self.expect_ident()
            return self.pool.add_node(NK_PAT_TYPED_BIND, start, self.prev_end(), name, type_sym, 0)
        // Variable binding
        return self.pool.add_node(NK_PAT_IDENT, start, self.prev_end(), name, 0, 0)

    if t == TK_DOT_IDENT:
        let text = self.source.slice((start + 1) as i64, end as i64)
        let name = self.intern.intern(text)
        self.advance()
        if self.peek() == TK_L_PAREN:
            self.advance()
            let extra_start = self.pool.extra_len()
            var binding_count = 0
            while self.peek() != TK_R_PAREN and self.peek() != TK_EOF:
                let b = self.expect_ident()
                self.pool.add_extra(b)
                binding_count = binding_count + 1
                if self.peek() == TK_COMMA:
                    self.advance()
                    self.skip_newlines()
            self.expect(TK_R_PAREN)
            return self.pool.add_node(NK_PAT_ENUM_SHORTHAND, start, self.prev_end(), name, extra_start, binding_count)
        return self.pool.add_node(NK_PAT_ENUM_SHORTHAND, start, self.prev_end(), name, 0, 0)

    if t == TK_L_PAREN:
        self.advance()
        let extra_start = self.pool.extra_len()
        var count = 0
        if self.peek() != TK_R_PAREN:
            let p = self.parse_pattern()
            self.pool.add_extra(p)
            count = count + 1
            while self.peek() == TK_COMMA:
                self.advance()
                self.skip_newlines()
                if self.peek() == TK_R_PAREN:
                    break
                let p2 = self.parse_pattern()
                self.pool.add_extra(p2)
                count = count + 1
        self.expect(TK_R_PAREN)
        return self.pool.add_node(NK_PAT_TUPLE, start, self.prev_end(), extra_start, count, 0)

    if t == TK_L_BRACE:
        return self.parse_struct_pattern(0, start)

    if t == TK_L_BRACKET:
        return self.parse_slice_pattern(start)

    self.emit_error("expected pattern")
    0

fn Parser.parse_struct_pattern(self: Parser, type_name: i32, start: i32) -> i32:
    self.advance()  // consume {
    self.skip_newlines()
    let extra_start = self.pool.extra_len()
    let has_rest_idx = self.pool.add_extra(0)
    var field_count = 0
    var has_rest = 0

    while self.peek() != TK_R_BRACE and self.peek() != TK_EOF:
        self.skip_newlines()
        if self.peek() == TK_DOT_DOT:
            has_rest = 1
            self.advance()
            if self.peek() == TK_COMMA:
                self.advance()
            self.skip_newlines()
            continue
        let fname = self.expect_ident()
        var fpat = 0
        if self.peek() == TK_COLON:
            self.advance()
            self.skip_newlines()
            fpat = self.parse_pattern()
        self.pool.add_extra(fname)
        self.pool.add_extra(fpat)
        field_count = field_count + 1
        if self.peek() == TK_COMMA:
            self.advance()
            self.skip_newlines()

    self.expect(TK_R_BRACE)
    self.pool.extra.set_i32(has_rest_idx as i64, has_rest)
    self.pool.add_node(NK_PAT_STRUCT, start, self.prev_end(), type_name, extra_start, field_count)

fn Parser.parse_slice_pattern(self: Parser, start: i32) -> i32:
    self.advance()  // consume [
    let extra_start = self.pool.extra_len()
    var head_count = 0
    var rest_sym = 0
    var has_rest = 0
    let tail_syms: Vec[i32] = Vec.new()
    // Placeholder slots: has_rest, head_count will be set after
    let has_rest_idx = self.pool.add_extra(0)

    while self.peek() != TK_R_BRACKET and self.peek() != TK_EOF:
        if self.peek() == TK_DOT_DOT:
            has_rest = 1
            self.advance()
            if self.peek() == TK_IDENT:
                rest_sym = self.expect_ident()
            if self.peek() == TK_COMMA:
                self.advance()
            self.skip_newlines()
            continue
        if self.peek() == TK_IDENT:
            let name = self.expect_ident()
            if has_rest != 0:
                tail_syms.push(name)
            else:
                self.pool.add_extra(name)
                head_count = head_count + 1
        else:
            break
        if self.peek() == TK_COMMA:
            self.advance()
            self.skip_newlines()

    self.expect(TK_R_BRACKET)
    self.pool.extra.set_i32(has_rest_idx as i64, has_rest)
    self.pool.add_extra(tail_syms.len() as i32)
    for ti in 0..tail_syms.len() as i32:
        self.pool.add_extra(tail_syms.get(ti as i64))
    self.pool.add_node(NK_PAT_SLICE, start, self.prev_end(), extra_start, head_count, rest_sym)

// ── Let binding expression ───────────────────────────────────────

fn Parser.parse_let_binding(self: Parser) -> i32:
    let start = self.current_start()
    let is_var = self.peek() == TK_KW_VAR
    self.advance()
    var is_mut = is_var
    if not is_var and self.peek() == TK_KW_MUT:
        is_mut = true
        self.advance()

    // Tuple destructuring (currently supports flat identifier/wildcard bindings).
    if self.peek() == TK_L_PAREN:
        self.advance()
        self.skip_newlines()
        let names: Vec[i32] = Vec.new()
        while self.peek() != TK_R_PAREN and self.peek() != TK_EOF:
            if self.peek() == TK_IDENT:
                let n_sym = self.intern_current()
                self.advance()
                if self.intern.resolve(n_sym) == "_":
                    names.push(0)
                else:
                    names.push(n_sym)
            else:
                self.emit_error("tuple destructuring requires identifier bindings")
                while self.peek() != TK_COMMA and self.peek() != TK_R_PAREN and self.peek() != TK_EOF:
                    self.advance()

            self.skip_newlines()
            if self.peek() == TK_COMMA:
                self.advance()
                self.skip_newlines()
            else:
                break

        self.expect(TK_R_PAREN)
        if self.expect(TK_EQ) == 0:
            return 0
        self.skip_newlines()
        let value = self.parse_expr()
        let extra_start = self.pool.extra_len()
        for ni in 0..names.len() as i32:
            self.pool.add_extra(names.get(ni as i64))
        return self.pool.add_node(NK_TUPLE_DESTRUCTURE, start, self.prev_end(), extra_start, names.len() as i32, value)

    // Let-else with variant shorthand: let .Some(v) = expr else body
    if self.peek() == TK_DOT_IDENT:
        let dot_start = self.current_start()
        let dot_end = self.current_end()
        let dot_text = self.source.slice((dot_start + 1) as i64, dot_end as i64)
        let dot_sym = self.intern.intern(dot_text)
        self.advance()
        if self.peek() == TK_L_PAREN:
            self.advance()
            let extra_start = self.pool.extra_len()
            var binding_count = 0
            while self.peek() != TK_R_PAREN and self.peek() != TK_EOF:
                let b = self.expect_ident()
                let pat_node = self.pool.add_node(NK_PAT_IDENT, self.prev_start(), self.prev_end(), b, 0, 0)
                self.pool.add_extra(pat_node)
                binding_count = binding_count + 1
                if self.peek() == TK_COMMA:
                    self.advance()
                    self.skip_newlines()
            self.expect(TK_R_PAREN)
            if self.expect(TK_EQ) == 0:
                return 0
            self.skip_newlines()
            let value = self.parse_expr()
            self.expect(TK_KW_ELSE)
            self.skip_newlines()
            let else_body = self.parse_expr()
            let pat = self.pool.add_node(NK_PAT_ENUM_SHORTHAND, dot_start, self.prev_end(), dot_sym, extra_start, binding_count)
            return self.pool.add_node(NK_LET_ELSE, start, self.prev_end(), pat, value, else_body)
        if self.peek() == TK_EQ:
            self.advance()
            self.skip_newlines()
            let value = self.parse_expr()
            if self.peek() == TK_KW_ELSE:
                self.advance()
                self.skip_newlines()
                let else_body = self.parse_expr()
                let pat = self.pool.add_node(NK_PAT_ENUM_SHORTHAND, dot_start, self.prev_end(), dot_sym, 0, 0)
                return self.pool.add_node(NK_LET_ELSE, start, self.prev_end(), pat, value, else_body)

    let name_sym = self.expect_ident()
    if name_sym == 0:
        return 0
    let name_str = self.intern.resolve(name_sym)
    let is_upper = name_str.len() > 0 and name_str.byte_at((0) as i64) >= 65 and name_str.byte_at((0) as i64) <= 90

    // Let-else variant: let Some(x) = expr else body
    if is_upper and self.peek() == TK_L_PAREN:
        self.advance()
        let extra_start = self.pool.extra_len()
        var binding_count = 0
        while self.peek() != TK_R_PAREN and self.peek() != TK_EOF:
            let b = self.expect_ident()
            let pat_node = self.pool.add_node(NK_PAT_IDENT, self.prev_start(), self.prev_end(), b, 0, 0)
            self.pool.add_extra(pat_node)
            binding_count = binding_count + 1
            if self.peek() == TK_COMMA:
                self.advance()
                self.skip_newlines()
        self.expect(TK_R_PAREN)
        if self.expect(TK_EQ) == 0:
            return 0
        self.skip_newlines()
        let value = self.parse_expr()
        self.expect(TK_KW_ELSE)
        self.skip_newlines()
        let else_body = self.parse_expr()
        let pat = self.pool.add_node(NK_PAT_VARIANT, start, self.prev_end(), name_sym, extra_start, binding_count)
        return self.pool.add_node(NK_LET_ELSE, start, self.prev_end(), pat, value, else_body)

    if is_upper and self.peek() == TK_EQ:
        self.advance()
        self.skip_newlines()
        let value = self.parse_expr()
        if self.peek() == TK_KW_ELSE:
            self.advance()
            self.skip_newlines()
            let else_body = self.parse_expr()
            let pat = self.pool.add_node(NK_PAT_VARIANT, start, self.prev_end(), name_sym, 0, 0)
            return self.pool.add_node(NK_LET_ELSE, start, self.prev_end(), pat, value, else_body)
        // Normal let binding
        var flags = 0
        if is_mut:
            flags = 1
        return self.pool.add_node(NK_LET_BINDING, start, self.prev_end(), name_sym, value, flags)

    var type_ann = 0
    if self.peek() == TK_COLON:
        self.advance()
        type_ann = self.parse_type_expr()

    if self.expect(TK_EQ) == 0:
        return 0
    self.skip_newlines()
    let value = self.parse_expr()
    var flags = 0
    if is_mut:
        flags = 1
    if type_ann != 0:
        let type_extra = self.pool.extra_len()
        self.pool.add_extra(type_ann)
        // Keep bit 0 for mut; encode optional type at bit 1+.
        flags = flags + (type_extra + 1) * 2
    self.pool.add_node(NK_LET_BINDING, start, self.prev_end(), name_sym, value, flags)

fn Parser.parse_const_binding(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()  // consume 'const'
    let name_sym = self.expect_ident()
    if name_sym == 0:
        return 0

    if self.peek() != TK_COLON:
        self.emit_error("const declaration requires a type annotation")
        return 0
    self.advance()
    let type_ann = self.parse_type_expr()

    if self.expect(TK_EQ) == 0:
        return 0
    self.skip_newlines()
    let raw_value = self.parse_expr()
    // const desugars to comptime-wrapped immutable let
    let value = self.pool.add_node(NK_COMPTIME, start, self.prev_end(), raw_value, 0, 0)

    var flags = 0
    if type_ann != 0:
        let type_extra = self.pool.extra_len()
        self.pool.add_extra(type_ann)
        flags = flags + (type_extra + 1) * 2
    self.pool.add_node(NK_LET_BINDING, start, self.prev_end(), name_sym, value, flags)

// ── With expression ──────────────────────────────────────────────

fn Parser.parse_with_expr(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    self.skip_newlines()
    self.suppress_as = 1
    let source = self.parse_expr()
    self.suppress_as = 0
    if self.peek() != TK_KW_AS:
        self.emit_error("expected 'as' in with expression")
        return 0
    self.advance()
    var is_mut = 0
    if self.peek() == TK_KW_MUT:
        is_mut = 1
        self.advance()
    let name = self.expect_ident()
    if self.peek() == TK_COLON:
        self.advance()
    let body = self.parse_block_or_expr()
    let encoded_name = encode_with_binding(name, is_mut)
    self.pool.add_node(NK_WITH_EXPR, start, self.prev_end(), source, body, encoded_name)

// ── Record update ────────────────────────────────────────────────

fn Parser.parse_record_update(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()  // consume {
    self.skip_newlines()
    let source = self.parse_expr()
    if self.peek() != TK_KW_WITH:
        self.emit_error("expected 'with' in record update")
        return 0
    self.advance()
    self.skip_newlines()

    var fields: Vec[i32] = Vec.new()
    var field_count = 0
    while self.peek() != TK_R_BRACE and self.peek() != TK_EOF:
        let fname = self.expect_ident()
        var val = 0
        if self.peek() == TK_COLON:
            self.advance()
            self.skip_newlines()
            val = self.parse_expr()
        else:
            val = self.pool.add_node(NK_IDENT, start, self.prev_end(), fname, 0, 0)
        fields.push(fname)
        fields.push(val)
        field_count = field_count + 1
        self.skip_newlines()
        if self.peek() == TK_COMMA:
            self.advance()
            self.skip_newlines()
    self.expect(TK_R_BRACE)
    let extra_start = self.pool.extra_len()
    for fi in 0..fields.len() as i32:
        self.pool.add_extra(fields.get(fi as i64))
    self.pool.add_node(NK_RECORD_UPDATE, start, self.prev_end(), source, extra_start, field_count)

// ── Array literal / comprehension ────────────────────────────────

fn Parser.parse_array_literal(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()  // consume [
    self.skip_newlines()
    var elems: Vec[i32] = Vec.new()

    if self.peek() != TK_R_BRACKET:
        let first = self.parse_expr()

        // Comprehension: [expr for x in iter]
        if self.peek() == TK_KW_FOR:
            self.advance()
            let binding = self.expect_ident()
            self.expect(TK_KW_IN)
            let iterable = self.parse_expr()
            var filter = 0
            if self.peek() == TK_KW_IF:
                self.advance()
                filter = self.parse_expr()
            self.expect(TK_R_BRACKET)
            return self.pool.add_node(NK_ARRAY_COMPREHENSION, start, self.prev_end(), first, binding, iterable)

        elems.push(first)

        while self.peek() == TK_COMMA:
            self.advance()
            self.skip_newlines()
            if self.peek() == TK_R_BRACKET:
                break
            elems.push(self.parse_expr())

    self.expect(TK_R_BRACKET)
    let extra_start = self.pool.extra_len()
    let count = elems.len() as i32
    for ei in 0..count:
        self.pool.add_extra(elems.get(ei as i64))
    self.pool.add_node(NK_ARRAY_LIT, start, self.prev_end(), extra_start, count, 0)

// ── Closure ──────────────────────────────────────────────────────

// Scan ahead (non-consuming) to check if we're inside a paren closure.
// Called after consuming '(' (and possibly newlines).
// Returns 1 if matching ')' is followed by '=>' or '->', 0 otherwise.
fn Parser.scan_is_paren_closure(self: Parser) -> i32:
    var scan = self.pos
    var depth = 1
    while scan < self.tokens.len():
        let tag = self.tokens.get_tag(scan)
        if tag == TK_L_PAREN:
            depth = depth + 1
        else if tag == TK_R_PAREN:
            depth = depth - 1
            if depth == 0:
                let next = scan + 1
                if next < self.tokens.len():
                    let nt = self.tokens.get_tag(next)
                    if nt == TK_FAT_ARROW: return 1
                    if nt == TK_ARROW: return 1
                return 0
        else if tag == TK_EOF:
            return 0
        scan = scan + 1
    0

// Parse: IDENT => expr (single untyped parameter fat-arrow closure)
fn Parser.parse_fat_arrow_single(self: Parser) -> i32:
    let start = self.current_start()
    let param_sym = self.expect_ident()
    self.expect(TK_FAT_ARROW)
    let extra_start = self.pool.extra_len()
    self.pool.add_extra(param_sym)
    self.pool.add_extra(0)
    let body = self.parse_block_or_expr()
    self.pool.add_node(NK_CLOSURE, start, self.prev_end(), body, extra_start, 1)

// Parse: (params) [-> RetType] => expr (paren fat-arrow closure)
// Starts at '(' token.
fn Parser.parse_fat_arrow_paren_closure(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()  // consume (
    self.skip_newlines()
    let extra_start = self.pool.extra_len()
    var param_count = 0
    while self.peek() != TK_R_PAREN and self.peek() != TK_EOF:
        if self.peek() == TK_KW_IT:
            self.emit_error("'it' is a reserved keyword and cannot be used as a parameter name")
            self.advance()
            self.pool.add_extra(0)
            self.pool.add_extra(0)
            param_count = param_count + 1
            if self.peek() == TK_COMMA:
                self.advance()
                self.skip_newlines()
            continue
        let p = self.expect_ident()
        if p == 0:
            self.advance()
            continue
        self.pool.add_extra(p)
        if self.peek() == TK_COLON:
            self.advance()
            let ty = self.parse_type_expr()
            self.pool.add_extra(ty)
        else:
            self.pool.add_extra(0)
        param_count = param_count + 1
        if self.peek() == TK_COMMA:
            self.advance()
            self.skip_newlines()
    self.expect(TK_R_PAREN)
    self.skip_newlines()
    // Optional return type
    if self.peek() == TK_ARROW:
        self.advance()
        self.parse_type_expr()
        self.skip_newlines()
    self.expect(TK_FAT_ARROW)
    let body = self.parse_block_or_expr()
    self.pool.add_node(NK_CLOSURE, start, self.prev_end(), body, extra_start, param_count)

fn Parser.parse_closure(self: Parser) -> i32:
    let start = self.current_start()
    self.expect(TK_PIPE)
    let extra_start = self.pool.extra_len()
    var param_count = 0
    while self.peek() != TK_PIPE and self.peek() != TK_EOF:
        if self.peek() == TK_KW_IT:
            self.emit_error("'it' is a reserved keyword and cannot be used as a parameter name")
            self.advance()
            self.pool.add_extra(0)
            self.pool.add_extra(0)
            param_count = param_count + 1
            if self.peek() == TK_COMMA:
                self.advance()
                self.skip_newlines()
            continue
        let p = self.expect_ident()
        if p == 0:
            self.advance()
            continue
        self.pool.add_extra(p)
        // Optional type
        if self.peek() == TK_COLON:
            self.advance()
            let ty = self.parse_type_expr()
            self.pool.add_extra(ty)
        else:
            self.pool.add_extra(0)
        param_count = param_count + 1
        if self.peek() == TK_COMMA:
            self.advance()
            self.skip_newlines()
    self.expect(TK_PIPE)
    self.skip_newlines()

    // Optional return type
    if self.peek() == TK_ARROW:
        self.advance()
        self.parse_type_expr()
        self.skip_newlines()

    let body = if self.peek() == TK_COLON:
        self.advance()
        self.parse_block_or_expr()
    else:
        self.parse_expr()
    self.pool.add_node(NK_CLOSURE, start, self.prev_end(), body, extra_start, param_count)

fn Parser.parse_move_closure(self: Parser) -> i32:
    let node = self.parse_closure()
    if node != 0:
        self.pool.mark_move_closure(node)
    node

// ── Block / indentation parsing ──────────────────────────────────

fn Parser.parse_block_or_expr(self: Parser) -> i32:
    if self.peek() != TK_NEWLINE:
        return self.parse_expr()

    self.skip_newlines()
    if self.peek() == TK_EOF:
        self.emit_error("expected expression")
        return 0

    let block_col = column_of(self.source, self.current_start())
    var stmts: Vec[i32] = Vec.new()
    var last_expr = self.parse_expr()

    while true:
        if self.peek() != TK_NEWLINE and self.peek() != TK_EOF:
            break
        if self.peek() == TK_EOF:
            break

        let save = self.pos
        self.skip_newlines()
        if self.peek() == TK_EOF:
            break
        let next_col = column_of(self.source, self.current_start())
        if next_col < block_col:
            self.pos = save
            break

        stmts.push(last_expr)
        last_expr = self.parse_expr()

    if stmts.len() == 0:
        return last_expr

    let extra_start = self.pool.extra_len()
    for i in 0..stmts.len() as i32:
        self.pool.add_extra(stmts.get(i as i64))

    let stmt_count = stmts.len() as i32
    self.pool.add_node(NK_BLOCK, self.pool.get_start(stmts.get(0)), self.pool.get_end(last_expr), extra_start, stmt_count, last_expr)

// ── Type expression parsing ──────────────────────────────────────

fn Parser.parse_type_expr(self: Parser) -> i32:
    let t = self.peek()
    let start = self.current_start()

    if t == TK_AMPERSAND:
        self.advance()
        var is_mut = 0
        if self.peek() == TK_KW_MUT:
            is_mut = 1
            self.advance()
        let pointee = self.parse_type_expr()
        return self.pool.add_node(NK_TYPE_REF, start, self.prev_end(), pointee, is_mut, 0)

    if t == TK_QUESTION:
        self.advance()
        let inner = self.parse_type_expr()
        return self.pool.add_node(NK_TYPE_OPTIONAL, start, self.prev_end(), inner, 0, 0)

    if t == TK_L_PAREN:
        self.advance()
        var elems: Vec[i32] = Vec.new()
        if self.peek() != TK_R_PAREN:
            let ty = self.parse_type_expr()
            elems.push(ty)
            while self.peek() == TK_COMMA:
                self.advance()
                let ty2 = self.parse_type_expr()
                elems.push(ty2)
        self.expect(TK_R_PAREN)
        let extra_start = self.pool.extra_len()
        for ei in 0..elems.len() as i32:
            self.pool.add_extra(elems.get(ei as i64))
        let count = elems.len() as i32
        return self.pool.add_node(NK_TYPE_TUPLE, start, self.prev_end(), extra_start, count, 0)

    if t == TK_KW_FN:
        self.advance()
        self.expect(TK_L_PAREN)
        var params: Vec[i32] = Vec.new()
        if self.peek() != TK_R_PAREN:
            let ty = self.parse_type_expr()
            params.push(ty)
            while self.peek() == TK_COMMA:
                self.advance()
                let ty2 = self.parse_type_expr()
                params.push(ty2)
        self.expect(TK_R_PAREN)
        self.expect(TK_ARROW)
        let ret = self.parse_type_expr()
        let extra_start = self.pool.extra_len()
        for pi in 0..params.len() as i32:
            self.pool.add_extra(params.get(pi as i64))
        let count = params.len() as i32
        return self.pool.add_node(NK_TYPE_FN, start, self.prev_end(), extra_start, count, ret)

    if t == TK_STAR:
        self.advance()
        var is_mut = 0
        if self.peek() == TK_KW_MUT:
            is_mut = 1
            self.advance()
        else if self.peek() == TK_KW_CONST:
            self.advance()
        let pointee = self.parse_type_expr()
        return self.pool.add_node(NK_TYPE_PTR, start, self.prev_end(), pointee, is_mut, 0)

    if t == TK_L_BRACKET:
        self.advance()
        if self.peek() == TK_R_BRACKET:
            self.advance()
            let elem = self.parse_type_expr()
            return self.pool.add_node(NK_TYPE_SLICE, start, self.prev_end(), elem, 0, 0)
        // Alternate slice syntax: [T]
        if self.peek() != TK_INT_LIT:
            let elem = self.parse_type_expr()
            self.expect(TK_R_BRACKET)
            return self.pool.add_node(NK_TYPE_SLICE, start, self.prev_end(), elem, 0, 0)
        if self.peek() == TK_INT_LIT:
            let ss = self.current_start()
            let se = self.current_end()
            let size_text = self.source.slice(ss as i64, se as i64)
            let size = parse_int(size_text)
            self.advance()
            self.expect(TK_R_BRACKET)
            let elem = self.parse_type_expr()
            return self.pool.add_node(NK_TYPE_ARRAY, start, self.prev_end(), elem, size, 0)
        self.emit_error("expected array size")
        return 0

    if t == TK_KW_DYN:
        self.advance()
        if self.peek() != TK_IDENT:
            self.emit_error("expected trait name after 'dyn'")
            return 0
        let sym = self.intern_current()
        self.advance()
        return self.pool.add_node(NK_TYPE_TRAIT_OBJ, start, self.prev_end(), sym, 0, 0)

    if t == TK_KW_IMPL:
        self.advance()
        if self.peek() != TK_IDENT:
            self.emit_error("expected trait name after 'impl'")
            return 0
        let sym = self.intern_current()
        self.advance()
        if self.peek() == TK_KW_FOR:
            self.advance()
        let target = self.parse_type_expr()
        if target == 0:
            return 0
        return self.pool.add_node(NK_TYPE_TRAIT_OBJ, start, self.prev_end(), sym, 0, 0)

    if t == TK_IDENT:
        let sym = self.intern_current()
        self.advance()
        if self.peek() == TK_DOT_IDENT:
            // Self.Output — dot + uppercase ident combined by lexer
            let dot_s = self.current_start()
            let dot_e = self.current_end()
            let assoc_text = self.source.slice((dot_s + 1) as i64, dot_e as i64)
            let assoc_sym = self.intern.intern(assoc_text)
            self.advance()
            return self.pool.add_node(NK_TYPE_ASSOC, start, self.prev_end(), sym, assoc_sym, 0)
        if self.peek() == TK_DOT:
            // Self.output — dot + lowercase ident are separate tokens
            self.advance()
            let assoc_sym = self.expect_ident()
            return self.pool.add_node(NK_TYPE_ASSOC, start, self.prev_end(), sym, assoc_sym, 0)
        if self.peek() == TK_L_BRACKET:
            self.advance()
            var args: Vec[i32] = Vec.new()
            if self.peek() != TK_R_BRACKET:
                while self.peek() != TK_R_BRACKET and self.peek() != TK_EOF:
                    let ty = self.parse_type_expr()
                    args.push(ty)
                    if self.peek() != TK_COMMA:
                        break
                    self.advance()
                    if self.peek() == TK_R_BRACKET:
                        break
            self.expect(TK_R_BRACKET)
            let extra_start = self.pool.extra_len()
            for ai in 0..args.len() as i32:
                self.pool.add_extra(args.get(ai as i64))
            let count = args.len() as i32
            return self.pool.add_node(NK_TYPE_GENERIC, start, self.prev_end(), sym, extra_start, count)
        return self.pool.add_node(NK_TYPE_NAMED, start, self.prev_end(), sym, 0, 0)

    self.emit_error("expected type")
    0

// ── Parameter list ───────────────────────────────────────────────

fn Parser.parse_param_list(self: Parser) -> i32:
    var params: Vec[i32] = Vec.new()
    let pattern_start = self.pool.fn_param_patterns_len()
    var pattern_count = 0
    var required_count = 0
    self.last_param_pattern_start = pattern_start
    self.last_param_pattern_count = 0
    self.last_param_required_count = 0
    if self.peek() == TK_R_PAREN or self.peek() == TK_DOT_DOT_DOT:
        return 0
    while true:
        var is_mut = 0
        if self.peek() == TK_KW_MUT:
            is_mut = 1
            self.advance()

        var name = 0
        var param_pattern = 0
        if self.peek() == TK_IDENT:
            name = self.expect_ident()
        else:
            let t = self.peek()
            if t == TK_L_PAREN or t == TK_L_BRACE or t == TK_L_BRACKET or t == TK_DOT_IDENT:
                param_pattern = self.parse_pattern()
                let synth = "__param_pat_" ++ int_to_string(self.pos) ++ "_" ++ int_to_string((params.len() / 2) as i32)
                name = self.intern.intern(synth)
            else:
                name = self.expect_ident()
        if name == 0:
            break

        var type_node = 0
        if self.peek() == TK_COLON:
            self.advance()
            type_node = self.parse_type_expr()

        // Default value
        var has_default = 0
        if self.peek() == TK_EQ:
            self.advance()
            self.parse_expr()
            has_default = 1
        if has_default == 0:
            required_count = required_count + 1

        params.push(name)
        params.push(type_node)
        self.pool.add_fn_param_pattern_value(param_pattern)
        pattern_count = pattern_count + 1

        if self.peek() != TK_COMMA:
            break
        self.advance()
        self.skip_newlines()
        if self.peek() == TK_R_PAREN or self.peek() == TK_DOT_DOT_DOT:
            break

    let count = (params.len() / 2) as i32
    for pi in 0..params.len() as i32:
        self.pool.add_extra(params.get(pi as i64))
    self.last_param_pattern_start = pattern_start
    self.last_param_pattern_count = pattern_count
    self.last_param_required_count = required_count
    count

fn Parser.parse_one_param(self: Parser) -> i32:
    var is_mut = 0
    if self.peek() == TK_KW_MUT:
        is_mut = 1
        self.advance()
    let name = self.expect_ident()
    if name == 0:
        return 0
    var type_node = 0
    if self.peek() == TK_COLON:
        self.advance()
        type_node = self.parse_type_expr()
    // Default value
    if self.peek() == TK_EQ:
        self.advance()
        self.parse_expr()
    self.pool.add_extra(name)
    self.pool.add_extra(type_node)
    1

// ── Type parameters ──────────────────────────────────────────────

fn Parser.parse_type_params(self: Parser) -> i32:
    if self.peek() != TK_L_BRACKET:
        return 0
    self.advance()
    var count = 0
    if self.peek() != TK_R_BRACKET:
        count = count + self.parse_one_type_param()
        while self.peek() == TK_COMMA:
            self.advance()
            if self.peek() == TK_R_BRACKET:
                break
            count = count + self.parse_one_type_param()
    self.expect(TK_R_BRACKET)
    count

fn Parser.parse_one_type_param(self: Parser) -> i32:
    if self.peek() == TK_KW_CONST:
        self.emit_error("const generics are reserved for future use")
        self.advance()
    let name = self.expect_ident()
    self.pool.add_extra(name)
    let count_idx = self.pool.add_extra(0)
    var bound_count = 0
    if self.peek() == TK_COLON:
        self.advance()
        let b = self.parse_type_bound_symbol()
        self.pool.add_extra(b)
        bound_count = bound_count + 1
        while self.peek() == TK_PLUS:
            self.advance()
            let b2 = self.parse_type_bound_symbol()
            self.pool.add_extra(b2)
            bound_count = bound_count + 1
    self.pool.extra.set_i32(count_idx as i64, bound_count)
    1

fn Parser.parse_type_bound_symbol(self: Parser) -> i32:
    if self.peek() == TK_IDENT:
        let sym = self.expect_ident()
        // Consume optional parameterized bound: Trait[Item=Type, ...] or Trait[T]
        if self.peek() == TK_L_BRACKET:
            self.advance()
            var depth = 1
            while depth > 0 and self.peek() != TK_EOF:
                if self.peek() == TK_L_BRACKET:
                    depth = depth + 1
                if self.peek() == TK_R_BRACKET:
                    depth = depth - 1
                    if depth == 0:
                        self.advance()
                        break
                self.advance()
        return sym
    if self.peek() == TK_KW_TYPE:
        self.advance()
        return self.intern.intern("type")
    self.emit_error("expected type bound name")
    0

fn Parser.parse_optional_where_clause(self: Parser):
    self.last_where_start = 0
    self.last_where_count = 0
    if self.peek() != TK_KW_WHERE and not self.is_ident_named("where"):
        return
    self.advance()
    // Collect all where clause entries into local vecs first
    var wp_syms: Vec[i32] = Vec.new()
    var wp_bound_starts: Vec[i32] = Vec.new()
    var wp_bound_counts: Vec[i32] = Vec.new()
    var wp_bounds_flat: Vec[i32] = Vec.new()
    while self.peek() == TK_IDENT:
        let type_param = self.intern_current()
        self.advance()
        self.expect(TK_COLON)
        wp_syms.push(type_param)
        wp_bound_starts.push(wp_bounds_flat.len() as i32)
        var bound_count = 0
        let b = self.parse_type_bound_symbol()
        if b != 0:
            wp_bounds_flat.push(b)
            bound_count = bound_count + 1
        while self.peek() == TK_PLUS:
            self.advance()
            let b2 = self.parse_type_bound_symbol()
            if b2 != 0:
                wp_bounds_flat.push(b2)
                bound_count = bound_count + 1
        wp_bound_counts.push(bound_count)
        if self.peek() != TK_COMMA:
            break
        self.advance()
    // Now write to extra pool: [type_param, bound_count, bounds...]*
    self.last_where_start = self.pool.extra_len()
    self.last_where_count = wp_syms.len() as i32
    for wi in 0..self.last_where_count:
        self.pool.add_extra(wp_syms.get(wi as i64))
        let bc = wp_bound_counts.get(wi as i64)
        self.pool.add_extra(bc)
        let bs = wp_bound_starts.get(wi as i64)
        for bi in 0..bc:
            self.pool.add_extra(wp_bounds_flat.get((bs + bi) as i64))

// ── Integer parsing helper ───────────────────────────────────────

fn parse_int(text: str) -> i32:
    let value = parse_i64(text)
    if value < -2147483648:
        return (0 - 2147483648) as i32
    if value > 2147483647:
        return 2147483647
    value as i32

fn parse_i64(text: str) -> i64:
    let len = text.len() as i32
    if len == 0:
        return 0
    if len > 2 and text.byte_at(0) == 48 and (text.byte_at(1) == 120 or text.byte_at(1) == 88):
        var val: i64 = 0
        var i = 2
        while i < len:
            let ch = text.byte_at(i as i64)
            if ch == 95:
                i = i + 1
                continue
            var digit: i64 = 0
            if ch >= 48 and ch <= 57:
                digit = (ch - 48) as i64
            else if ch >= 97 and ch <= 102:
                digit = (ch - 87) as i64
            else if ch >= 65 and ch <= 70:
                digit = (ch - 55) as i64
            val = val * 16 + digit
            i = i + 1
        return val
    if len > 2 and text.byte_at(0) == 48 and (text.byte_at(1) == 98 or text.byte_at(1) == 66):
        var val: i64 = 0
        var i = 2
        while i < len:
            let ch = text.byte_at(i as i64)
            if ch == 95:
                i = i + 1
                continue
            let digit = if ch == 49: 1 else: 0
            val = val * 2 + digit
            i = i + 1
        return val
    if len > 2 and text.byte_at(0) == 48 and (text.byte_at(1) == 111 or text.byte_at(1) == 79):
        var val: i64 = 0
        var i = 2
        while i < len:
            let ch = text.byte_at(i as i64)
            if ch == 95:
                i = i + 1
                continue
            let digit = (ch - 48) as i64
            val = val * 8 + digit
            i = i + 1
        return val
    var end_pos = len
    var si = 0
    while si < len:
        if text.byte_at(si as i64) == 95:
            let remain = len - si
            if remain >= 4:
                let c1 = text.byte_at((si + 1) as i64)
                if c1 == 105 or c1 == 117:
                    end_pos = si
                    break
        si = si + 1
    var clean = ""
    var i = 0
    while i < end_pos:
        let ch = text.byte_at(i as i64)
        if ch != 95:
            clean = clean ++ str_from_byte(ch)
        i = i + 1
    with_parse_i64(clean)
