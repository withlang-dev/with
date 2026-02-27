// Parser — Recursive descent parser: tokens → AST.
//
// The parser consumes a TokenList and produces an AstPool.
// All AST nodes are index-based (i32 handles into the pool).
// On parse errors, the parser recovers by skipping to the
// next top-level declaration.
//
// Node encoding conventions (d0/d1/d2 = data fields, extra = overflow):
//   NK_FN_DECL:      d0=name_str, d1=body, d2=extra_start
//     extra: [param_count, flags, ret_type, p1_name, p1_type, ...]
//   NK_TYPE_DECL:    d0=name_str, d1=extra_start, d2=flags
//     flags: bit0=pub, bits1-2=TDK_*
//   NK_USE_DECL:     d0=path_str
//   NK_LET_DECL:     d0=name_str, d1=init, d2=type_node
//   NK_EXTERN_FN:    d0=name_str, d1=extra_start, d2=flags
//     extra: [param_count, ret_type, p1_name, p1_type, ...]
//   NK_INT_LIT:      d0=str_idx
//   NK_FLOAT_LIT:    d0=str_idx
//   NK_STRING_LIT:   d0=str_idx
//   NK_BOOL_LIT:     d0=0/1
//   NK_IDENT:        d0=str_idx
//   NK_BINARY:       d0=lhs, d1=rhs, d2=op
//   NK_UNARY:        d0=operand, d1=op
//   NK_CALL:         d0=callee, d1=extra_start, d2=arg_count
//     extra: [arg1, arg2, ...]
//   NK_FIELD_ACCESS: d0=object, d1=field_str
//   NK_INDEX:        d0=object, d1=index
//   NK_BLOCK:        d0=extra_start, d1=stmt_count, d2=tail
//     extra: [stmt1, stmt2, ...]
//   NK_IF_EXPR:      d0=cond, d1=then_body, d2=else_body (0=none)
//   NK_RETURN:       d0=value (0=none)
//   NK_LET_BINDING:  d0=name_str, d1=init, d2=type_node (0=inferred)
//   NK_ASSIGN:       d0=target, d1=value
//   NK_WHILE:        d0=cond, d1=body
//   NK_LOOP:         d0=body
//   NK_FOR:          d0=binding_str, d1=iterable, d2=body
//   NK_BREAK:        d0=value (0=none)
//   NK_CONTINUE:     (no data)
//   NK_MATCH:        d0=subject, d1=extra_start, d2=arm_count
//     extra: [arm1_node, arm2_node, ...]
//   NK_MATCH_ARM:    d0=pattern, d1=body, d2=guard (0=none)
//   NK_CAST:         d0=expr, d1=type_node
//   NK_DEFER:        d0=expr
//   NK_PIPELINE:     d0=lhs, d1=rhs
//   NK_RANGE:        d0=start, d1=end, d2=inclusive
//   NK_GROUPED:      d0=inner
//   NK_TUPLE:        d0=extra_start, d1=count; extra: [e1, e2, ...]
//   NK_ARRAY_LIT:    d0=extra_start, d1=count; extra: [e1, e2, ...]
//   NK_STRUCT_LIT:   d0=type_str, d1=extra_start, d2=field_count
//     extra: [name1, val1, name2, val2, ...]
//   NK_CLOSURE:      d0=body, d1=extra_start, d2=param_count
//     extra: [p1_name, p1_type, ...] (type=0 if untyped)
//   NK_SLICE:        d0=object, d1=start, d2=end (0=open)
//   NK_VARIANT_SHORTHAND: d0=name_str, d1=extra_start, d2=arg_count
//     extra: [arg1, arg2, ...]
//   NK_SPAWN:        d0=expr
//   NK_COMPTIME:     d0=expr
//   NK_YIELD:        d0=expr
//   NK_AWAIT:        d0=expr
//   NK_WITH_EXPR:    d0=source, d1=name_str, d2=body
//   NK_RECORD_UPDATE: d0=source, d1=extra_start, d2=field_count

use Token
use Lexer
use Ast

extern fn i32_to_str(n: i32) -> str

fn PARSER_TRACE() -> i32: 0

type Parser = {
    tokens: TokenList,
    pos: i32,
    source: str,
    pool: AstPool,
    suppress_as: bool,
    trace_ticks: i32,
    trace_last_pos: i32,
    trace_same_pos: i32,
}

fn Parser.new(tokens: TokenList, source: str) -> Parser:
    var p = Parser {
        tokens: tokens,
        pos: 0,
        source: source,
        pool: AstPool.new(),
        suppress_as: false,
        trace_ticks: 0,
        trace_last_pos: -1,
        trace_same_pos: 0,
    }
    // Reserve node 0 as "null/none" sentinel
    AstPool.add_node(p.pool, 0, 0, 0, 0, 0, 0)
    p

// ── Token helpers ──────────────────────────────────────────────

fn Parser.peek(self: *mut Parser) -> i32:
    if self.pos >= TokenList.len(self.tokens):
        return TK_EOF()
    TokenList.tag_at(self.tokens, self.pos)

fn Parser.advance(self: *mut Parser) -> void:
    if self.pos < TokenList.len(self.tokens):
        self.pos = self.pos + 1

fn Parser.cur_start(self: *mut Parser) -> i32:
    if self.pos >= TokenList.len(self.tokens):
        return 0
    TokenList.start_at(self.tokens, self.pos)

fn Parser.cur_end(self: *mut Parser) -> i32:
    if self.pos >= TokenList.len(self.tokens):
        return 0
    TokenList.end_at(self.tokens, self.pos)

fn Parser.prev_end(self: *mut Parser) -> i32:
    if self.pos > 0:
        return TokenList.end_at(self.tokens, self.pos - 1)
    0

fn Parser.token_text(self: *mut Parser) -> str:
    let s = Parser.cur_start(self)
    let e = Parser.cur_end(self)
    self.source.slice(s as i64, e as i64)

fn Parser.intern(self: *mut Parser) -> i32:
    AstPool.add_string(self.pool, Parser.token_text(self))

fn Parser.expect(self: *mut Parser, tag: i32) -> bool:
    if Parser.peek(self) == tag:
        Parser.advance(self)
        return true
    false

fn Parser.skip_nl(self: *mut Parser) -> void:
    while Parser.peek(self) == TK_NEWLINE():
        Parser.advance(self)

fn Parser.trace(self: *mut Parser, label: str) -> void:
    if PARSER_TRACE() == 0:
        return
    self.trace_ticks = self.trace_ticks + 1
    // Keep logs bounded while still showing EOF progression.
    if (self.trace_ticks % 1000) != 0:
        return
    let len = TokenList.len(self.tokens)
    let tag = Parser.peek(self)
    println("[PARSER] " ++ label ++ " ticks=" ++ i32_to_str(self.trace_ticks) ++ " pos=" ++ i32_to_str(self.pos) ++ "/" ++ i32_to_str(len) ++ " tag=" ++ tag_name(tag))
    if self.pos == self.trace_last_pos:
        self.trace_same_pos = self.trace_same_pos + 1
    if self.pos != self.trace_last_pos:
        self.trace_last_pos = self.pos
        self.trace_same_pos = 0
    if self.trace_same_pos >= 10:
        println("[PARSER] no-pos-progress x" ++ i32_to_str(self.trace_same_pos) ++ " at pos=" ++ i32_to_str(self.pos) ++ " tag=" ++ tag_name(tag))
        self.trace_same_pos = 0

fn Parser.is_ident_named(self: *mut Parser, name: str) -> bool:
    if Parser.peek(self) != TK_IDENT():
        return false
    Parser.token_text(self) == name

fn column_of(source: str, pos: i32) -> i32:
    var p = pos
    while p > 0:
        p = p - 1
        if source[p] == 10:
            return pos - p - 1
    pos

fn is_upper(ch: i32) -> bool:
    ch >= 65 and ch <= 90

// ── Entry point ────────────────────────────────────────────────

fn Parser.parse_module(self: *mut Parser) -> void:
    if PARSER_TRACE() != 0:
        let len0 = TokenList.len(self.tokens)
        println("[PARSER] module-start len=" ++ i32_to_str(len0) ++ " pos=" ++ i32_to_str(self.pos) ++ " first=" ++ tag_name(Parser.peek(self)))
    Parser.skip_nl(self)
    // Skip optional module declaration
    if Parser.peek(self) == TK_KW_MODULE():
        Parser.advance(self)
        if Parser.peek(self) == TK_IDENT():
            Parser.advance(self)
        while Parser.peek(self) == TK_DOT():
            Parser.advance(self)
            if Parser.peek(self) == TK_IDENT():
                Parser.advance(self)
        Parser.skip_nl(self)

    while Parser.peek(self) != TK_EOF():
        Parser.trace(self, "parse_module")
        Parser.skip_nl(self)
        Parser.skip_attributes(self)
        Parser.skip_nl(self)
        if Parser.peek(self) == TK_EOF():
            break
        // Handle impl/extend blocks
        if Parser.peek(self) == TK_KW_PUB():
            let saved = self.pos
            Parser.advance(self)
            if Parser.peek(self) == TK_KW_IMPL() or Parser.peek(self) == TK_KW_EXTEND():
                Parser.parse_impl_block(self, true)
                Parser.skip_nl(self)
                continue
            if Parser.peek(self) == TK_KW_TRAIT():
                let decl = Parser.parse_trait_decl(self, true)
                if decl > 0:
                    AstPool.add_decl(self.pool, decl)
                Parser.skip_nl(self)
                continue
            self.pos = saved
        if Parser.peek(self) == TK_KW_IMPL() or Parser.peek(self) == TK_KW_EXTEND():
            Parser.parse_impl_block(self, false)
            Parser.skip_nl(self)
            continue
        if Parser.peek(self) == TK_KW_TRAIT():
            let decl = Parser.parse_trait_decl(self, false)
            if decl > 0:
                AstPool.add_decl(self.pool, decl)
            Parser.skip_nl(self)
            continue
        let decl = Parser.parse_decl(self)
        if decl < 0:
            Parser.recover_to_top_level(self)
        if decl > 0:
            AstPool.add_decl(self.pool, decl)
        Parser.skip_nl(self)
    if PARSER_TRACE() != 0:
        let dc = AstPool.decl_count(self.pool)
        println("[PARSER] module-end decls=" ++ i32_to_str(dc) ++ " pos=" ++ i32_to_str(self.pos) ++ " peek=" ++ tag_name(Parser.peek(self)))

fn Parser.skip_attributes(self: *mut Parser) -> void:
    while Parser.peek(self) == TK_AT():
        Parser.advance(self)
        if Parser.peek(self) == TK_L_BRACKET():
            Parser.advance(self)
            var depth = 1
            while depth > 0 and Parser.peek(self) != TK_EOF():
                if Parser.peek(self) == TK_L_BRACKET():
                    depth = depth + 1
                if Parser.peek(self) == TK_R_BRACKET():
                    depth = depth - 1
                Parser.advance(self)

// ── Declaration parsing ────────────────────────────────────────

fn Parser.parse_decl(self: *mut Parser) -> i32:
    let start = Parser.cur_start(self)
    var is_pub = false
    if Parser.peek(self) == TK_KW_PUB():
        is_pub = true
        Parser.advance(self)
    let tag = Parser.peek(self)
    if tag == TK_KW_FN():
        return Parser.parse_fn_decl(self, is_pub, start, 0)
    if tag == TK_KW_COMPTIME():
        Parser.advance(self)
        if Parser.peek(self) == TK_KW_FN():
            return Parser.parse_fn_decl(self, is_pub, start, FN_FLAG_COMPTIME())
        return -1
    if tag == TK_KW_ASYNC():
        Parser.advance(self)
        if Parser.peek(self) == TK_KW_FN():
            return Parser.parse_fn_decl(self, is_pub, start, FN_FLAG_ASYNC())
        return -1
    if tag == TK_KW_GEN():
        Parser.advance(self)
        if Parser.peek(self) == TK_KW_FN():
            return Parser.parse_fn_decl(self, is_pub, start, FN_FLAG_GEN())
        return -1
    if tag == TK_KW_TYPE():
        return Parser.parse_type_decl(self, is_pub, start)
    if tag == TK_KW_USE():
        return Parser.parse_use_decl(self, start)
    if tag == TK_KW_LET() or tag == TK_KW_VAR():
        return Parser.parse_top_level_let(self, is_pub, start)
    if tag == TK_KW_EXTERN():
        return Parser.parse_extern_decl(self, start)
    if tag == TK_KW_ERROR():
        // Skip error declarations for now
        while Parser.peek(self) != TK_NEWLINE() and Parser.peek(self) != TK_EOF():
            Parser.advance(self)
        return AstPool.add_node(self.pool, NK_POISONED_DECL(), start, Parser.cur_start(self), 0, 0, 0)
    -1

// ── Function declaration ───────────────────────────────────────

fn Parser.parse_fn_decl(self: *mut Parser, is_pub: bool, start: i32, extra_flags: i32) -> i32:
    Parser.advance(self)  // consume 'fn'
    if Parser.peek(self) != TK_IDENT():
        return -1
    var fn_name = Parser.intern(self)
    Parser.advance(self)

    // Handle Type.method syntax: fn Type.method(...)
    if Parser.peek(self) == TK_DOT():
        Parser.advance(self)
        if Parser.peek(self) == TK_IDENT():
            let type_name = AstPool.get_string(self.pool, fn_name)
            let method = Parser.token_text(self)
            fn_name = AstPool.add_string(self.pool, type_name ++ "." ++ method)
            Parser.advance(self)

    // Parse optional type parameters [T, U: Trait]
    if Parser.peek(self) == TK_L_BRACKET():
        Parser.advance(self)
        while Parser.peek(self) != TK_R_BRACKET() and Parser.peek(self) != TK_EOF():
            Parser.advance(self)
        Parser.expect(self, TK_R_BRACKET())

    // Parse parameter list — accumulate into extra later
    // We use two Vec[i32] for temp storage of param names and types
    var p_names = Vec.new()
    var p_types = Vec.new()
    var param_count = 0
    var flags = extra_flags
    if is_pub:
        flags = flags | FN_FLAG_PUB()

    if Parser.peek(self) == TK_L_PAREN():
        Parser.advance(self)
        while Parser.peek(self) != TK_R_PAREN() and Parser.peek(self) != TK_EOF():
            if param_count > 0:
                if Parser.peek(self) == TK_COMMA():
                    Parser.advance(self)
                    Parser.skip_nl(self)
            // Optional 'mut'
            if Parser.peek(self) == TK_KW_MUT():
                Parser.advance(self)
            if Parser.peek(self) == TK_IDENT():
                let pn = Parser.intern(self)
                Parser.advance(self)
                var pt = 0
                if Parser.peek(self) == TK_COLON():
                    Parser.advance(self)
                    Parser.skip_nl(self)
                    pt = Parser.parse_type_expr(self)
                p_names.push(pn)
                p_types.push(pt)
                param_count = param_count + 1
            if Parser.peek(self) == TK_DOT_DOT_DOT():
                flags = flags | FN_FLAG_VARIADIC()
                Parser.advance(self)
        Parser.expect(self, TK_R_PAREN())

    // Parse optional return type
    var ret_type = 0
    if Parser.peek(self) == TK_ARROW():
        Parser.advance(self)
        Parser.skip_nl(self)
        ret_type = Parser.parse_type_expr(self)

    // Parse optional where clause — skip for now
    if Parser.is_ident_named(self, "where"):
        Parser.advance(self)
        while Parser.peek(self) != TK_COLON() and Parser.peek(self) != TK_EQ() and Parser.peek(self) != TK_NEWLINE() and Parser.peek(self) != TK_EOF():
            Parser.advance(self)

    // Emit signature to extra: [param_count, flags, ret_type, p1_name, p1_type, ...]
    let extra_start = AstPool.extra_len(self.pool)
    AstPool.add_extra(self.pool, param_count)
    AstPool.add_extra(self.pool, flags)
    AstPool.add_extra(self.pool, ret_type)
    var pi = 0
    while pi < param_count:
        AstPool.add_extra(self.pool, p_names.get(pi as i64))
        AstPool.add_extra(self.pool, p_types.get(pi as i64))
        pi = pi + 1

    // Expect ':' or '=' body introducer
    if Parser.peek(self) != TK_COLON() and Parser.peek(self) != TK_EQ():
        // No body — might be a declaration-only fn (in trait)
        let end = Parser.cur_start(self)
        return AstPool.add_node(self.pool, NK_FN_DECL(), start, end, fn_name, 0, extra_start)
    Parser.advance(self)  // consume ':' or '='

    // Parse body
    let body = Parser.parse_block_or_expr(self)
    let end = Parser.cur_start(self)
    AstPool.add_node(self.pool, NK_FN_DECL(), start, end, fn_name, body, extra_start)

// ── Type declaration ───────────────────────────────────────────

fn Parser.parse_type_decl(self: *mut Parser, is_pub: bool, start: i32) -> i32:
    Parser.advance(self)  // consume 'type'
    if Parser.peek(self) != TK_IDENT():
        return -1
    let name_str = Parser.intern(self)
    Parser.advance(self)

    // Skip optional type parameters [T]
    if Parser.peek(self) == TK_L_BRACKET():
        Parser.advance(self)
        while Parser.peek(self) != TK_R_BRACKET() and Parser.peek(self) != TK_EOF():
            Parser.advance(self)
        Parser.expect(self, TK_R_BRACKET())

    Parser.expect(self, TK_EQ())
    Parser.skip_nl(self)

    var kind_bits = TDK_ALIAS()
    if is_pub:
        kind_bits = kind_bits | 1  // pub bit

    // Check what follows
    if Parser.peek(self) == TK_L_BRACE():
        // Struct definition: { field: Type, ... }
        return Parser.parse_struct_def(self, name_str, start, is_pub)

    // Check for 'distinct'
    if Parser.is_ident_named(self, "distinct"):
        Parser.advance(self)
        let inner = Parser.parse_type_expr(self)
        var fl = TDK_DISTINCT() * 2
        if is_pub:
            fl = fl | 1
        let extra_start = AstPool.extra_len(self.pool)
        AstPool.add_extra(self.pool, inner)
        let end = Parser.cur_start(self)
        return AstPool.add_node(self.pool, NK_TYPE_DECL(), start, end, name_str, extra_start, fl)

    // Check for enum (identifier followed by | or at column > 0)
    if Parser.is_enum_start(self):
        return Parser.parse_enum_def(self, name_str, start, is_pub)

    // Type alias
    let aliased = Parser.parse_type_expr(self)
    var fl2 = TDK_ALIAS() * 2
    if is_pub:
        fl2 = fl2 | 1
    let extra_start = AstPool.extra_len(self.pool)
    AstPool.add_extra(self.pool, aliased)
    let end = Parser.cur_start(self)
    AstPool.add_node(self.pool, NK_TYPE_DECL(), start, end, name_str, extra_start, fl2)

fn Parser.is_enum_start(self: *mut Parser) -> bool:
    // Peek ahead to check for enum pattern: Ident | Ident or just Ident on new line
    if Parser.peek(self) != TK_IDENT():
        return false
    let text = Parser.token_text(self)
    // If the identifier starts with uppercase, it could be a variant
    if text.len() == 0:
        return false
    if not is_upper(text[0]):
        return false
    // Save pos and look for | after the ident
    let saved = self.pos
    Parser.advance(self)
    // Skip optional payload
    if Parser.peek(self) == TK_L_PAREN():
        var depth = 1
        Parser.advance(self)
        while depth > 0 and Parser.peek(self) != TK_EOF():
            if Parser.peek(self) == TK_L_PAREN():
                depth = depth + 1
            if Parser.peek(self) == TK_R_PAREN():
                depth = depth - 1
            Parser.advance(self)
    let is_enum = Parser.peek(self) == TK_PIPE() or Parser.peek(self) == TK_NEWLINE()
    self.pos = saved
    is_enum

fn Parser.parse_struct_def(self: *mut Parser, name_str: i32, start: i32, is_pub: bool) -> i32:
    Parser.advance(self)  // consume '{'
    Parser.skip_nl(self)
    var field_names = Vec.new()
    var field_types = Vec.new()
    var field_defaults = Vec.new()
    var field_count = 0
    while Parser.peek(self) != TK_R_BRACE() and Parser.peek(self) != TK_EOF():
        if Parser.peek(self) != TK_IDENT():
            Parser.advance(self)
            continue
        let f_name = Parser.intern(self)
        Parser.advance(self)
        // Struct fields must be `name: Type`.
        if Parser.peek(self) != TK_COLON():
            // Recover within struct body if this isn't a field entry.
            while Parser.peek(self) != TK_COMMA() and Parser.peek(self) != TK_NEWLINE() and Parser.peek(self) != TK_R_BRACE() and Parser.peek(self) != TK_EOF():
                Parser.advance(self)
            if Parser.peek(self) == TK_COMMA():
                Parser.advance(self)
            Parser.skip_nl(self)
            continue
        Parser.advance(self)
        Parser.skip_nl(self)
        let f_type = Parser.parse_type_expr(self)
        var f_default = 0
        if Parser.peek(self) == TK_EQ():
            Parser.advance(self)
            Parser.skip_nl(self)
            f_default = Parser.parse_expr(self)
        field_names.push(f_name)
        field_types.push(f_type)
        field_defaults.push(f_default)
        field_count = field_count + 1
        Parser.skip_nl(self)
        if Parser.peek(self) == TK_COMMA():
            Parser.advance(self)
            Parser.skip_nl(self)
    Parser.expect(self, TK_R_BRACE())
    let extra_start = AstPool.extra_len(self.pool)
    AstPool.add_extra(self.pool, 0)  // placeholder for compatibility
    var fi = 0
    while fi < field_count:
        AstPool.add_extra(self.pool, field_names.get(fi as i64))
        AstPool.add_extra(self.pool, field_types.get(fi as i64))
        AstPool.add_extra(self.pool, field_defaults.get(fi as i64))
        fi = fi + 1
    // We can't update field_count placeholder... use the flags encoding instead
    var fl = TDK_STRUCT() * 2
    if is_pub:
        fl = fl | 1
    // Encode field_count in the extra data by creating a separate node
    // Actually: store field_count in d2 upper bits
    // d2 = (field_count << 8) | fl
    let encoded_flags = field_count * 256 + fl
    let end = Parser.cur_start(self)
    AstPool.add_node(self.pool, NK_TYPE_DECL(), start, end, name_str, extra_start + 1, encoded_flags)

fn Parser.parse_enum_def(self: *mut Parser, name_str: i32, start: i32, is_pub: bool) -> i32:
    var variant_names = Vec.new()
    var variant_payload_counts = Vec.new()
    var variant_payload_types = Vec.new()
    var variant_count = 0
    // Variants can be separated by | or newlines
    while Parser.peek(self) != TK_EOF():
        if Parser.peek(self) == TK_PIPE():
            Parser.advance(self)
            Parser.skip_nl(self)
        if Parser.peek(self) != TK_IDENT():
            break
        // Check column — if at column 0, we're back to top-level
        let col = column_of(self.source, Parser.cur_start(self))
        if col == 0 and variant_count > 0:
            break
        let v_name = Parser.intern(self)
        Parser.advance(self)
        var payload_count = 0
        if Parser.peek(self) == TK_L_PAREN():
            Parser.advance(self)
            while Parser.peek(self) != TK_R_PAREN() and Parser.peek(self) != TK_EOF():
                if payload_count > 0:
                    if Parser.peek(self) == TK_COMMA():
                        Parser.advance(self)
                        Parser.skip_nl(self)
                let payload_type = Parser.parse_type_expr(self)
                variant_payload_types.push(payload_type)
                payload_count = payload_count + 1
            Parser.expect(self, TK_R_PAREN())
        variant_names.push(v_name)
        variant_payload_counts.push(payload_count)
        variant_count = variant_count + 1
        Parser.skip_nl(self)
    let extra_start = AstPool.extra_len(self.pool)
    AstPool.add_extra(self.pool, 0)  // placeholder for compatibility with readers
    var vi = 0
    var pi = 0
    while vi < variant_count:
        AstPool.add_extra(self.pool, variant_names.get(vi as i64))
        let payload_count = variant_payload_counts.get(vi as i64)
        AstPool.add_extra(self.pool, payload_count)
        var pj = 0
        while pj < payload_count:
            AstPool.add_extra(self.pool, variant_payload_types.get(pi as i64))
            pi = pi + 1
            pj = pj + 1
        vi = vi + 1
    var fl = TDK_ENUM() * 2
    if is_pub:
        fl = fl | 1
    let encoded_flags = variant_count * 256 + fl
    let end = Parser.cur_start(self)
    AstPool.add_node(self.pool, NK_TYPE_DECL(), start, end, name_str, extra_start, encoded_flags)

// ── Use declaration ────────────────────────────────────────────

fn Parser.parse_use_decl(self: *mut Parser, start: i32) -> i32:
    Parser.advance(self)  // consume 'use'
    // Build path string
    if Parser.peek(self) != TK_IDENT() and Parser.peek(self) != TK_KW_C_IMPORT():
        return -1
    // c_import
    if Parser.peek(self) == TK_KW_C_IMPORT():
        Parser.advance(self)
        Parser.expect(self, TK_L_PAREN())
        var header_str = 0
        if Parser.peek(self) == TK_STRING_LIT():
            header_str = Parser.intern(self)
            Parser.advance(self)
        // Skip optional link: "lib" arg
        while Parser.peek(self) != TK_R_PAREN() and Parser.peek(self) != TK_EOF():
            Parser.advance(self)
        Parser.expect(self, TK_R_PAREN())
        let end = Parser.cur_start(self)
        return AstPool.add_node(self.pool, NK_C_IMPORT(), start, end, header_str, 0, 0)

    var path = Parser.token_text(self)
    Parser.advance(self)
    while Parser.peek(self) == TK_DOT():
        Parser.advance(self)
        if Parser.peek(self) == TK_IDENT() or Parser.peek(self) == TK_DOT_IDENT():
            path = path ++ "." ++ Parser.token_text(self)
            Parser.advance(self)
        if Parser.peek(self) == TK_STAR():
            path = path ++ ".*"
            Parser.advance(self)
    let path_str = AstPool.add_string(self.pool, path)
    let end = Parser.cur_start(self)
    AstPool.add_node(self.pool, NK_USE_DECL(), start, end, path_str, 0, 0)

// ── Top-level let/var ──────────────────────────────────────────

fn Parser.parse_top_level_let(self: *mut Parser, is_pub: bool, start: i32) -> i32:
    let is_var = Parser.peek(self) == TK_KW_VAR()
    Parser.advance(self)  // consume let/var
    if Parser.peek(self) != TK_IDENT():
        return -1
    let name_str = Parser.intern(self)
    Parser.advance(self)
    var type_node = 0
    if Parser.peek(self) == TK_COLON():
        Parser.advance(self)
        Parser.skip_nl(self)
        type_node = Parser.parse_type_expr(self)
    var init_node = 0
    if Parser.peek(self) == TK_EQ():
        Parser.advance(self)
        Parser.skip_nl(self)
        init_node = Parser.parse_expr(self)
    let end = Parser.cur_start(self)
    AstPool.add_node(self.pool, NK_LET_DECL(), start, end, name_str, init_node, type_node)

// ── Extern function ────────────────────────────────────────────

fn Parser.parse_extern_decl(self: *mut Parser, start: i32) -> i32:
    Parser.advance(self)  // consume 'extern'
    if Parser.peek(self) != TK_KW_FN():
        return -1
    Parser.advance(self)  // consume 'fn'
    if Parser.peek(self) != TK_IDENT():
        return -1
    let name_str = Parser.intern(self)
    Parser.advance(self)
    let extra_start = AstPool.extra_len(self.pool)
    var param_count = 0
    var is_variadic = false
    // Collect params into temp vecs
    var pn = Vec.new()
    var pt = Vec.new()
    if Parser.peek(self) == TK_L_PAREN():
        Parser.advance(self)
        while Parser.peek(self) != TK_R_PAREN() and Parser.peek(self) != TK_EOF():
            if param_count > 0:
                if Parser.peek(self) == TK_COMMA():
                    Parser.advance(self)
                    Parser.skip_nl(self)
            if Parser.peek(self) == TK_DOT_DOT_DOT():
                is_variadic = true
                Parser.advance(self)
                continue
            if Parser.peek(self) == TK_IDENT():
                let n = Parser.intern(self)
                Parser.advance(self)
                var t = 0
                if Parser.peek(self) == TK_COLON():
                    Parser.advance(self)
                    Parser.skip_nl(self)
                    t = Parser.parse_type_expr(self)
                pn.push(n)
                pt.push(t)
                param_count = param_count + 1
        Parser.expect(self, TK_R_PAREN())
    var ret_type = 0
    if Parser.peek(self) == TK_ARROW():
        Parser.advance(self)
        Parser.skip_nl(self)
        ret_type = Parser.parse_type_expr(self)
    // Emit extra: [param_count, ret_type, p1_name, p1_type, ...]
    AstPool.add_extra(self.pool, param_count)
    AstPool.add_extra(self.pool, ret_type)
    var ei = 0
    while ei < param_count:
        AstPool.add_extra(self.pool, pn.get(ei as i64))
        AstPool.add_extra(self.pool, pt.get(ei as i64))
        ei = ei + 1
    var fl = 0
    if is_variadic:
        fl = fl | FN_FLAG_VARIADIC()
    let end = Parser.cur_start(self)
    AstPool.add_node(self.pool, NK_EXTERN_FN(), start, end, name_str, extra_start, fl)

// ── Impl block ─────────────────────────────────────────────────

fn Parser.parse_impl_block(self: *mut Parser, is_pub: bool) -> void:
    Parser.advance(self)  // consume impl/extend
    if Parser.peek(self) != TK_IDENT():
        return
    let type_name_text = Parser.token_text(self)
    Parser.advance(self)
    // Check for 'for TypeName' (trait impl)
    var trait_name = ""
    if Parser.is_ident_named(self, "for") or Parser.peek(self) == TK_KW_FOR():
        trait_name = type_name_text
        Parser.advance(self)
        if Parser.peek(self) == TK_IDENT():
            // Actually: 'impl Trait for Type'
            // trait_name is Trait, type name is next
            let actual_type = Parser.token_text(self)
            Parser.advance(self)
            // Swap: type_name_text was the trait
            // For method mangling, use actual_type
            Parser.parse_impl_methods(self, actual_type, is_pub)
            return
    Parser.parse_impl_methods(self, type_name_text, is_pub)

fn Parser.parse_impl_methods(self: *mut Parser, type_name: str, is_pub: bool) -> void:
    Parser.skip_nl(self)
    while Parser.peek(self) != TK_EOF():
        let col = column_of(self.source, Parser.cur_start(self))
        if col == 0:
            break
        Parser.skip_attributes(self)
        Parser.skip_nl(self)
        if Parser.peek(self) == TK_EOF():
            break
        let col2 = column_of(self.source, Parser.cur_start(self))
        if col2 == 0:
            break
        if Parser.peek(self) != TK_KW_FN():
            // Skip unknown tokens inside impl block
            Parser.advance(self)
            Parser.skip_nl(self)
            continue
        let start = Parser.cur_start(self)
        Parser.advance(self)  // consume 'fn'
        if Parser.peek(self) != TK_IDENT():
            Parser.advance(self)
            continue
        let method_name = Parser.token_text(self)
        let mangled = type_name ++ "." ++ method_name
        let fn_name = AstPool.add_string(self.pool, mangled)
        Parser.advance(self)

        // Skip type params
        if Parser.peek(self) == TK_L_BRACKET():
            Parser.advance(self)
            while Parser.peek(self) != TK_R_BRACKET() and Parser.peek(self) != TK_EOF():
                Parser.advance(self)
            Parser.expect(self, TK_R_BRACKET())

        var pn2 = Vec.new()
        var pt2 = Vec.new()
        var pc = 0
        var fl = 0
        if is_pub:
            fl = fl | FN_FLAG_PUB()
        if Parser.peek(self) == TK_L_PAREN():
            Parser.advance(self)
            while Parser.peek(self) != TK_R_PAREN() and Parser.peek(self) != TK_EOF():
                if pc > 0:
                    if Parser.peek(self) == TK_COMMA():
                        Parser.advance(self)
                        Parser.skip_nl(self)
                if Parser.peek(self) == TK_KW_MUT():
                    Parser.advance(self)
                if Parser.peek(self) == TK_IDENT():
                    let n = Parser.intern(self)
                    Parser.advance(self)
                    var t = 0
                    if Parser.peek(self) == TK_COLON():
                        Parser.advance(self)
                        Parser.skip_nl(self)
                        t = Parser.parse_type_expr(self)
                    pn2.push(n)
                    pt2.push(t)
                    pc = pc + 1
                if Parser.peek(self) == TK_DOT_DOT_DOT():
                    fl = fl | FN_FLAG_VARIADIC()
                    Parser.advance(self)
            Parser.expect(self, TK_R_PAREN())

        var ret = 0
        if Parser.peek(self) == TK_ARROW():
            Parser.advance(self)
            Parser.skip_nl(self)
            ret = Parser.parse_type_expr(self)
        if Parser.is_ident_named(self, "where"):
            Parser.advance(self)
            while Parser.peek(self) != TK_COLON() and Parser.peek(self) != TK_EQ() and Parser.peek(self) != TK_NEWLINE() and Parser.peek(self) != TK_EOF():
                Parser.advance(self)

        let es = AstPool.extra_len(self.pool)
        AstPool.add_extra(self.pool, pc)
        AstPool.add_extra(self.pool, fl)
        AstPool.add_extra(self.pool, ret)
        var j = 0
        while j < pc:
            AstPool.add_extra(self.pool, pn2.get(j as i64))
            AstPool.add_extra(self.pool, pt2.get(j as i64))
            j = j + 1

        var body = 0
        if Parser.peek(self) == TK_COLON() or Parser.peek(self) == TK_EQ():
            Parser.advance(self)
            body = Parser.parse_block_or_expr(self)

        let decl = AstPool.add_node(self.pool, NK_FN_DECL(), start, Parser.cur_start(self), fn_name, body, es)
        AstPool.add_decl(self.pool, decl)
        Parser.skip_nl(self)

// ── Trait declaration ──────────────────────────────────────────

fn Parser.parse_trait_decl(self: *mut Parser, is_pub: bool) -> i32:
    let start = Parser.cur_start(self)
    Parser.advance(self)  // consume 'trait'
    if Parser.peek(self) != TK_IDENT():
        return -1
    let name_str = Parser.intern(self)
    Parser.advance(self)
    Parser.expect(self, TK_EQ())
    Parser.skip_nl(self)
    // Parse trait methods (signatures) — store as extra data
    var method_sigs = Vec.new()
    var method_count = 0
    while Parser.peek(self) != TK_EOF():
        let col = column_of(self.source, Parser.cur_start(self))
        if col == 0:
            break
        Parser.skip_nl(self)
        if Parser.peek(self) == TK_EOF():
            break
        let col2 = column_of(self.source, Parser.cur_start(self))
        if col2 == 0:
            break
        if Parser.peek(self) == TK_KW_FN():
            let fn_start = Parser.cur_start(self)
            let sig = Parser.parse_fn_decl(self, false, fn_start, 0)
            method_sigs.push(sig)
            method_count = method_count + 1
            Parser.skip_nl(self)
            continue
        if Parser.peek(self) == TK_KW_TYPE():
            while Parser.peek(self) != TK_NEWLINE() and Parser.peek(self) != TK_EOF():
                Parser.advance(self)
            Parser.skip_nl(self)
            continue
        Parser.advance(self)
    let extra_start = AstPool.extra_len(self.pool)
    var mi = 0
    while mi < method_count:
        AstPool.add_extra(self.pool, method_sigs.get(mi as i64))
        mi = mi + 1
    let end = Parser.cur_start(self)
    AstPool.add_node(self.pool, NK_TRAIT_DECL(), start, end, name_str, extra_start, method_count)

// ── Expression parsing ─────────────────────────────────────────

fn Parser.parse_expr(self: *mut Parser) -> i32:
    let lhs = Parser.parse_precedence(self, 0)
    if lhs <= 0:
        return lhs
    // Check for assignment: lhs = rhs
    if Parser.peek(self) == TK_EQ():
        Parser.advance(self)
        Parser.skip_nl(self)
        let rhs = Parser.parse_expr(self)
        let s = AstPool.get_start(self.pool, lhs)
        let e = Parser.cur_start(self)
        return AstPool.add_node(self.pool, NK_ASSIGN(), s, e, lhs, rhs, 0)
    // Compound assignment: +=, -=, *=, /=, %=
    let compound_op = Parser.compound_assign_op(self)
    if compound_op >= 0:
        Parser.advance(self)
        Parser.skip_nl(self)
        let rhs = Parser.parse_expr(self)
        let s = AstPool.get_start(self.pool, lhs)
        let e = Parser.cur_start(self)
        let bin = AstPool.add_node(self.pool, NK_BINARY(), s, e, lhs, rhs, compound_op)
        return AstPool.add_node(self.pool, NK_ASSIGN(), s, e, lhs, bin, 0)
    lhs

fn Parser.compound_assign_op(self: *mut Parser) -> i32:
    let t = Parser.peek(self)
    if t == TK_PLUS_EQ():
        return OP_ADD()
    if t == TK_MINUS_EQ():
        return OP_SUB()
    if t == TK_STAR_EQ():
        return OP_MUL()
    if t == TK_SLASH_EQ():
        return OP_DIV()
    if t == TK_PERCENT_EQ():
        return OP_MOD()
    -1

fn Parser.parse_index_expr(self: *mut Parser) -> i32:
    Parser.parse_precedence(self, 6)

// ── Pratt precedence climbing ──────────────────────────────────

fn Parser.parse_precedence(self: *mut Parser, min_prec: i32) -> i32:
    var lhs = Parser.parse_primary(self)
    if lhs <= 0:
        return lhs
    loop:
        let prec = infix_prec(Parser.peek(self))
        if prec == 0:
            break
        if prec < min_prec:
            break
        let tag = Parser.peek(self)
        Parser.advance(self)
        Parser.skip_nl(self)
        // Special: value |> match
        if tag == TK_PIPE_GT() and Parser.peek(self) == TK_KW_MATCH():
            Parser.advance(self)
            Parser.skip_nl(self)
            let arm_count = Parser.parse_match_arms(self)
            let arms_start = AstPool.extra_len(self.pool) - arm_count
            let s = AstPool.get_start(self.pool, lhs)
            let e = Parser.cur_start(self)
            lhs = AstPool.add_node(self.pool, NK_MATCH(), s, e, lhs, arms_start, arm_count)
            continue
        let right_assoc = tag == TK_QUESTION_QUESTION() or tag == TK_LT_PIPE()
        var rhs_min = prec + 1
        if right_assoc:
            rhs_min = prec
        let rhs = Parser.parse_precedence(self, rhs_min)
        let s = AstPool.get_start(self.pool, lhs)
        let e = Parser.cur_start(self)
        // Pipeline
        if tag == TK_PIPE_GT():
            lhs = AstPool.add_node(self.pool, NK_PIPELINE(), s, e, lhs, rhs, 0)
            continue
        if tag == TK_LT_PIPE():
            lhs = AstPool.add_node(self.pool, NK_PIPELINE(), s, e, rhs, lhs, 0)
            continue
        // Range
        if tag == TK_DOT_DOT():
            lhs = AstPool.add_node(self.pool, NK_RANGE(), s, e, lhs, rhs, 0)
            continue
        if tag == TK_DOT_DOT_EQ():
            lhs = AstPool.add_node(self.pool, NK_RANGE(), s, e, lhs, rhs, 1)
            continue
        // Default op ??
        if tag == TK_QUESTION_QUESTION():
            lhs = AstPool.add_node(self.pool, NK_BINARY(), s, e, lhs, rhs, OP_DEFAULT())
            continue
        // Normal binary
        let op = infix_op(tag)
        lhs = AstPool.add_node(self.pool, NK_BINARY(), s, e, lhs, rhs, op)
    lhs

fn infix_prec(tag: i32) -> i32:
    if tag == TK_KW_OR() then 1
    else if tag == TK_KW_AND() then 2
    else if tag == TK_EQ_EQ() or tag == TK_BANG_EQ() then 3
    else if tag == TK_LT() or tag == TK_GT() or tag == TK_LT_EQ() or tag == TK_GT_EQ() then 4
    else if tag == TK_DOT_DOT() or tag == TK_DOT_DOT_EQ() then 5
    else if tag == TK_PIPE_GT() or tag == TK_LT_PIPE() or tag == TK_GT_GT() or tag == TK_LT_LT() then 6
    else if tag == TK_AMPERSAND() then 7
    else if tag == TK_CARET() then 8
    else if tag == TK_PIPE() then 9
    else if tag == TK_QUESTION_QUESTION() then 10
    else if tag == TK_PLUS() or tag == TK_MINUS() or tag == TK_PLUS_PLUS() or tag == TK_PLUS_WRAP() or tag == TK_MINUS_WRAP() then 11
    else if tag == TK_STAR() or tag == TK_SLASH() or tag == TK_PERCENT() or tag == TK_STAR_WRAP() then 12
    else 0

fn infix_op(tag: i32) -> i32:
    if tag == TK_KW_OR() then OP_OR()
    else if tag == TK_KW_AND() then OP_AND()
    else if tag == TK_EQ_EQ() then OP_EQ()
    else if tag == TK_BANG_EQ() then OP_NEQ()
    else if tag == TK_LT() then OP_LT()
    else if tag == TK_GT() then OP_GT()
    else if tag == TK_LT_EQ() then OP_LTE()
    else if tag == TK_GT_EQ() then OP_GTE()
    else if tag == TK_AMPERSAND() then OP_BIT_AND()
    else if tag == TK_CARET() then OP_BIT_XOR()
    else if tag == TK_PIPE() then OP_BIT_OR()
    else if tag == TK_PLUS() then OP_ADD()
    else if tag == TK_MINUS() then OP_SUB()
    else if tag == TK_STAR() then OP_MUL()
    else if tag == TK_SLASH() then OP_DIV()
    else if tag == TK_PERCENT() then OP_MOD()
    else if tag == TK_PLUS_PLUS() then OP_CONCAT()
    else if tag == TK_GT_GT() then OP_SHR()
    else if tag == TK_LT_LT() then OP_SHL()
    else if tag == TK_PLUS_WRAP() then OP_ADD()
    else if tag == TK_MINUS_WRAP() then OP_SUB()
    else if tag == TK_STAR_WRAP() then OP_MUL()
    else 0

// ── Primary expression parsing ─────────────────────────────────

fn Parser.parse_primary(self: *mut Parser) -> i32:
    Parser.trace(self, "parse_primary")
    let tag = Parser.peek(self)
    if tag == TK_INT_LIT():
        return Parser.parse_int_lit(self)
    if tag == TK_FLOAT_LIT():
        return Parser.parse_float_lit(self)
    if tag == TK_STRING_LIT():
        return Parser.parse_string_lit(self)
    if tag == TK_C_STRING_LIT():
        return Parser.parse_c_string_lit(self)
    if tag == TK_TRUE() or tag == TK_FALSE():
        return Parser.parse_bool_lit(self)
    if tag == TK_IDENT():
        return Parser.parse_ident_or_call(self)
    if tag == TK_DOT_IDENT():
        return Parser.parse_variant_shorthand(self)
    if tag == TK_L_PAREN():
        return Parser.parse_grouped_or_tuple(self)
    if tag == TK_MINUS():
        return Parser.parse_unary_negate(self)
    if tag == TK_KW_NOT():
        return Parser.parse_unary_not(self)
    if tag == TK_AMPERSAND():
        return Parser.parse_ref_of(self)
    if tag == TK_STAR():
        return Parser.parse_deref(self)
    if tag == TK_KW_IF():
        return Parser.parse_if_expr(self)
    if tag == TK_KW_WHILE():
        return Parser.parse_while(self)
    if tag == TK_KW_LOOP():
        return Parser.parse_loop(self)
    if tag == TK_KW_FOR():
        return Parser.parse_for(self)
    if tag == TK_KW_RETURN():
        return Parser.parse_return(self)
    if tag == TK_KW_BREAK():
        return Parser.parse_break(self)
    if tag == TK_KW_CONTINUE():
        return Parser.parse_continue(self)
    if tag == TK_KW_DEFER():
        return Parser.parse_defer(self)
    if tag == TK_KW_MATCH():
        return Parser.parse_match_expr(self)
    if tag == TK_KW_LET() or tag == TK_KW_VAR():
        return Parser.parse_let_binding(self)
    if tag == TK_L_BRACKET():
        return Parser.parse_array_lit(self)
    if tag == TK_PIPE():
        return Parser.parse_closure(self)
    if tag == TK_KW_WITH():
        return Parser.parse_with_expr(self)
    if tag == TK_L_BRACE():
        return Parser.parse_record_update(self)
    if tag == TK_KW_SPAWN():
        let s = Parser.cur_start(self)
        Parser.advance(self)
        let inner = Parser.parse_expr(self)
        return AstPool.add_node(self.pool, NK_SPAWN(), s, Parser.cur_start(self), inner, 0, 0)
    if tag == TK_KW_YIELD():
        let s = Parser.cur_start(self)
        Parser.advance(self)
        let inner = Parser.parse_expr(self)
        return AstPool.add_node(self.pool, NK_YIELD(), s, Parser.cur_start(self), inner, 0, 0)
    if tag == TK_KW_COMPTIME():
        let s = Parser.cur_start(self)
        Parser.advance(self)
        let inner = Parser.parse_expr(self)
        return AstPool.add_node(self.pool, NK_COMPTIME(), s, Parser.cur_start(self), inner, 0, 0)
    if tag == TK_KW_UNSAFE():
        // Treat unsafe as transparent
        Parser.advance(self)
        return Parser.parse_block_or_expr(self)
    if tag == TK_LABEL():
        return Parser.parse_labeled_loop(self)
    -1

// ── Literals ───────────────────────────────────────────────────

fn Parser.parse_int_lit(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    let e = Parser.cur_end(self)
    let text_str = Parser.intern(self)
    Parser.advance(self)
    AstPool.add_node(self.pool, NK_INT_LIT(), s, e, text_str, 0, 0)

fn Parser.parse_float_lit(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    let e = Parser.cur_end(self)
    let text_str = Parser.intern(self)
    Parser.advance(self)
    AstPool.add_node(self.pool, NK_FLOAT_LIT(), s, e, text_str, 0, 0)

fn Parser.parse_string_lit(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    let e = Parser.cur_end(self)
    // Strip quotes from the source text
    let raw_text = Parser.token_text(self)
    var content = raw_text
    if raw_text.len() >= 2:
        content = raw_text.slice(1, raw_text.len() - 1)
    let str_idx = AstPool.add_string(self.pool, content)
    Parser.advance(self)
    let node = AstPool.add_node(self.pool, NK_STRING_LIT(), s, e, str_idx, 0, 0)
    Parser.parse_postfix(self, node)

fn Parser.parse_c_string_lit(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    let e = Parser.cur_end(self)
    let raw_text = Parser.token_text(self)
    var content = raw_text
    if raw_text.len() >= 3:
        content = raw_text.slice(2, raw_text.len() - 1)
    let str_idx = AstPool.add_string(self.pool, content)
    Parser.advance(self)
    AstPool.add_node(self.pool, NK_C_STRING_LIT(), s, e, str_idx, 0, 0)

fn Parser.parse_bool_lit(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    let e = Parser.cur_end(self)
    let val = if Parser.peek(self) == TK_TRUE() then 1 else 0
    Parser.advance(self)
    AstPool.add_node(self.pool, NK_BOOL_LIT(), s, e, val, 0, 0)

// ── Identifier and postfix ─────────────────────────────────────

fn Parser.parse_ident_or_call(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    let e = Parser.cur_end(self)
    let name = Parser.intern(self)
    Parser.advance(self)
    let node = AstPool.add_node(self.pool, NK_IDENT(), s, e, name, 0, 0)
    Parser.parse_postfix(self, node)

fn Parser.parse_postfix(self: *mut Parser, lhs_in: i32) -> i32:
    var lhs = lhs_in
    loop:
        let tag = Parser.peek(self)
        if tag == TK_L_PAREN():
            // Function call
            Parser.advance(self)
            var args = Vec.new()
            if Parser.peek(self) != TK_R_PAREN():
                let a = Parser.parse_expr(self)
                args.push(a)
                while Parser.peek(self) == TK_COMMA():
                    Parser.advance(self)
                    Parser.skip_nl(self)
                    let a2 = Parser.parse_expr(self)
                    args.push(a2)
            let s = AstPool.get_start(self.pool, lhs)
            let e = Parser.cur_end(self)
            Parser.expect(self, TK_R_PAREN())
            let extra_start = AstPool.extra_len(self.pool)
            let arg_count = args.len() as i32
            var ai = 0
            while ai < arg_count:
                AstPool.add_extra(self.pool, args.get(ai as i64))
                ai = ai + 1
            lhs = AstPool.add_node(self.pool, NK_CALL(), s, e, lhs, extra_start, arg_count)
            continue
        if tag == TK_DOT():
            Parser.advance(self)
            // .await postfix
            if Parser.peek(self) == TK_KW_AWAIT():
                let s = AstPool.get_start(self.pool, lhs)
                Parser.advance(self)
                lhs = AstPool.add_node(self.pool, NK_AWAIT(), s, Parser.cur_start(self), lhs, 0, 0)
                continue
            // field access .name or .0 (tuple)
            if Parser.peek(self) == TK_IDENT() or Parser.peek(self) == TK_INT_LIT():
                let field_str = Parser.intern(self)
                Parser.advance(self)
                let s = AstPool.get_start(self.pool, lhs)
                lhs = AstPool.add_node(self.pool, NK_FIELD_ACCESS(), s, Parser.cur_start(self), lhs, field_str, 0)
                continue
            break
        if tag == TK_L_BRACE():
            // Struct literal: Name { field: val, ... }
            // Only if lhs is an identifier
            if AstPool.kind(self.pool, lhs) != NK_IDENT():
                break
            let type_str = AstPool.get_data0(self.pool, lhs)
            Parser.advance(self)  // consume '{'
            Parser.skip_nl(self)
            var field_names = Vec.new()
            var field_vals = Vec.new()
            var field_count = 0
            while Parser.peek(self) != TK_R_BRACE() and Parser.peek(self) != TK_EOF():
                if Parser.peek(self) != TK_IDENT():
                    break
                let f_name = Parser.intern(self)
                Parser.advance(self)
                var f_val = 0
                if Parser.peek(self) == TK_COLON():
                    Parser.advance(self)
                    Parser.skip_nl(self)
                    f_val = Parser.parse_expr(self)
                if f_val == 0:
                    // Shorthand: name → name: name
                    f_val = AstPool.add_node(self.pool, NK_IDENT(), Parser.cur_start(self), Parser.cur_start(self), f_name, 0, 0)
                field_names.push(f_name)
                field_vals.push(f_val)
                field_count = field_count + 1
                Parser.skip_nl(self)
                if Parser.peek(self) == TK_COMMA():
                    Parser.advance(self)
                    Parser.skip_nl(self)
            let extra_start = AstPool.extra_len(self.pool)
            var fi = 0
            while fi < field_count:
                AstPool.add_extra(self.pool, field_names.get(fi as i64))
                AstPool.add_extra(self.pool, field_vals.get(fi as i64))
                fi = fi + 1
            let s = AstPool.get_start(self.pool, lhs)
            let e = Parser.cur_end(self)
            Parser.expect(self, TK_R_BRACE())
            lhs = AstPool.add_node(self.pool, NK_STRUCT_LIT(), s, e, type_str, extra_start, field_count)
            continue
        if tag == TK_L_BRACKET():
            // Array index or slice
            Parser.advance(self)
            let idx = Parser.parse_index_expr(self)
            if Parser.peek(self) == TK_DOT_DOT():
                // Slice: arr[start..end]
                Parser.advance(self)
                var end_expr = 0
                if Parser.peek(self) != TK_R_BRACKET():
                    end_expr = Parser.parse_expr(self)
                let s = AstPool.get_start(self.pool, lhs)
                let e = Parser.cur_end(self)
                Parser.expect(self, TK_R_BRACKET())
                lhs = AstPool.add_node(self.pool, NK_SLICE(), s, e, lhs, idx, end_expr)
                continue
            let s = AstPool.get_start(self.pool, lhs)
            let e = Parser.cur_end(self)
            Parser.expect(self, TK_R_BRACKET())
            lhs = AstPool.add_node(self.pool, NK_INDEX(), s, e, lhs, idx, 0)
            continue
        if tag == TK_KW_AS():
            if self.suppress_as:
                break
            Parser.advance(self)
            let target = Parser.parse_type_expr(self)
            let s = AstPool.get_start(self.pool, lhs)
            lhs = AstPool.add_node(self.pool, NK_CAST(), s, Parser.cur_start(self), lhs, target, 0)
            continue
        if tag == TK_QUESTION():
            // Postfix ? (try operator)
            let s = AstPool.get_start(self.pool, lhs)
            let e = Parser.cur_end(self)
            Parser.advance(self)
            lhs = AstPool.add_node(self.pool, NK_UNARY(), s, e, lhs, UOP_TRY(), 0)
            continue
        if tag == TK_QUESTION_DOT():
            // Optional chaining: expr?.field
            Parser.advance(self)
            if Parser.peek(self) == TK_IDENT() or Parser.peek(self) == TK_INT_LIT():
                let member = Parser.intern(self)
                Parser.advance(self)
                let s = AstPool.get_start(self.pool, lhs)
                lhs = AstPool.add_node(self.pool, NK_OPTIONAL_CHAIN(), s, Parser.cur_start(self), lhs, member, 0)
                continue
            break
        break
    lhs

// ── Unary expressions ──────────────────────────────────────────

fn Parser.parse_unary_negate(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    Parser.advance(self)
    let operand = Parser.parse_primary(self)
    AstPool.add_node(self.pool, NK_UNARY(), s, Parser.cur_start(self), operand, UOP_NEGATE(), 0)

fn Parser.parse_unary_not(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    Parser.advance(self)
    let operand = Parser.parse_primary(self)
    AstPool.add_node(self.pool, NK_UNARY(), s, Parser.cur_start(self), operand, UOP_NOT(), 0)

fn Parser.parse_ref_of(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    Parser.advance(self)
    var is_mut = false
    if Parser.peek(self) == TK_KW_MUT():
        is_mut = true
        Parser.advance(self)
    let operand = Parser.parse_primary(self)
    let op = if is_mut then UOP_MUT_REF() else UOP_REF()
    AstPool.add_node(self.pool, NK_UNARY(), s, Parser.cur_start(self), operand, op, 0)

fn Parser.parse_deref(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    Parser.advance(self)
    let operand = Parser.parse_primary(self)
    AstPool.add_node(self.pool, NK_UNARY(), s, Parser.cur_start(self), operand, UOP_DEREF(), 0)

// ── Variant shorthand ──────────────────────────────────────────

fn Parser.parse_variant_shorthand(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    let e = Parser.cur_end(self)
    // Strip leading dot from .Variant
    let text = Parser.token_text(self)
    let name = text.slice(1, text.len())
    let name_str = AstPool.add_string(self.pool, name)
    Parser.advance(self)
    // Check for payload: .Variant(args)
    var args = Vec.new()
    if Parser.peek(self) == TK_L_PAREN():
        Parser.advance(self)
        while Parser.peek(self) != TK_R_PAREN() and Parser.peek(self) != TK_EOF():
            if args.len() > 0:
                if Parser.peek(self) == TK_COMMA():
                    Parser.advance(self)
                    Parser.skip_nl(self)
            let arg = Parser.parse_expr(self)
            args.push(arg)
        Parser.expect(self, TK_R_PAREN())
    let extra_start = AstPool.extra_len(self.pool)
    let arg_count = args.len() as i32
    var ai = 0
    while ai < arg_count:
        AstPool.add_extra(self.pool, args.get(ai as i64))
        ai = ai + 1
    AstPool.add_node(self.pool, NK_VARIANT_SHORTHAND(), s, Parser.cur_start(self), name_str, extra_start, arg_count)

// ── Grouped / tuple ────────────────────────────────────────────

fn Parser.parse_grouped_or_tuple(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    Parser.advance(self)  // consume '('
    Parser.skip_nl(self)
    if Parser.peek(self) == TK_R_PAREN():
        // Empty tuple
        Parser.advance(self)
        return AstPool.add_node(self.pool, NK_TUPLE(), s, Parser.cur_start(self), 0, 0, 0)
    let first = Parser.parse_expr(self)
    if Parser.peek(self) == TK_COMMA():
        // Tuple
        var elems = Vec.new()
        elems.push(first)
        while Parser.peek(self) == TK_COMMA():
            Parser.advance(self)
            Parser.skip_nl(self)
            if Parser.peek(self) == TK_R_PAREN():
                break
            let elem = Parser.parse_expr(self)
            elems.push(elem)
        let e = Parser.cur_end(self)
        Parser.expect(self, TK_R_PAREN())
        let extra_start = AstPool.extra_len(self.pool)
        let count = elems.len() as i32
        var ei = 0
        while ei < count:
            AstPool.add_extra(self.pool, elems.get(ei as i64))
            ei = ei + 1
        return AstPool.add_node(self.pool, NK_TUPLE(), s, e, extra_start, count, 0)
    // Grouped expression
    let e = Parser.cur_end(self)
    Parser.expect(self, TK_R_PAREN())
    let node = AstPool.add_node(self.pool, NK_GROUPED(), s, e, first, 0, 0)
    Parser.parse_postfix(self, node)

// ── Control flow ───────────────────────────────────────────────

fn Parser.parse_if_expr(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    Parser.advance(self)  // consume 'if'
    // Parse condition
    let cond = Parser.parse_expr(self)
    // Accept 'then' or ':' as delimiter
    if Parser.peek(self) == TK_KW_THEN():
        Parser.advance(self)
    else if Parser.peek(self) == TK_COLON():
        Parser.advance(self)
    // Parse then body
    let then_body = Parser.parse_block_or_expr(self)
    // Check for else
    var else_body = 0
    let saved = self.pos
    Parser.skip_nl(self)
    if Parser.peek(self) != TK_KW_ELSE():
        // No else — restore position
        self.pos = saved
        let e = Parser.cur_start(self)
        return AstPool.add_node(self.pool, NK_IF_EXPR(), s, e, cond, then_body, 0)
    // We have else
    Parser.advance(self)
    if Parser.peek(self) == TK_KW_IF():
        else_body = Parser.parse_if_expr(self)
        let e = Parser.cur_start(self)
        return AstPool.add_node(self.pool, NK_IF_EXPR(), s, e, cond, then_body, else_body)
    if Parser.peek(self) == TK_COLON():
        Parser.advance(self)
    else_body = Parser.parse_block_or_expr(self)
    let e = Parser.cur_start(self)
    AstPool.add_node(self.pool, NK_IF_EXPR(), s, e, cond, then_body, else_body)

fn Parser.parse_while(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    Parser.advance(self)  // consume 'while'
    let cond = Parser.parse_expr(self)
    if Parser.peek(self) == TK_COLON():
        Parser.advance(self)
    let body = Parser.parse_block_or_expr(self)
    AstPool.add_node(self.pool, NK_WHILE(), s, Parser.cur_start(self), cond, body, 0)

fn Parser.parse_loop(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    Parser.advance(self)  // consume 'loop'
    if Parser.peek(self) == TK_COLON():
        Parser.advance(self)
    let body = Parser.parse_block_or_expr(self)
    AstPool.add_node(self.pool, NK_LOOP(), s, Parser.cur_start(self), body, 0, 0)

fn Parser.parse_for(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    Parser.advance(self)  // consume 'for'
    if Parser.peek(self) != TK_IDENT():
        return -1
    let binding = Parser.intern(self)
    Parser.advance(self)
    // Check for index binding: for x, i in ...
    var index_binding = 0
    if Parser.peek(self) == TK_COMMA():
        Parser.advance(self)
        if Parser.peek(self) == TK_IDENT():
            index_binding = Parser.intern(self)
            Parser.advance(self)
    // Expect 'in'
    Parser.expect(self, TK_KW_IN())
    let iterable = Parser.parse_expr(self)
    if Parser.peek(self) == TK_COLON():
        Parser.advance(self)
    let body = Parser.parse_block_or_expr(self)
    AstPool.add_node(self.pool, NK_FOR(), s, Parser.cur_start(self), binding, iterable, body)

fn Parser.parse_return(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    Parser.advance(self)  // consume 'return'
    var value = 0
    if Parser.peek(self) != TK_NEWLINE() and Parser.peek(self) != TK_EOF() and Parser.peek(self) != TK_R_PAREN() and Parser.peek(self) != TK_R_BRACE():
        value = Parser.parse_expr(self)
    AstPool.add_node(self.pool, NK_RETURN(), s, Parser.cur_start(self), value, 0, 0)

fn Parser.parse_break(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    Parser.advance(self)  // consume 'break'
    var value = 0
    if Parser.peek(self) != TK_NEWLINE() and Parser.peek(self) != TK_EOF():
        value = Parser.parse_expr(self)
    AstPool.add_node(self.pool, NK_BREAK(), s, Parser.cur_start(self), value, 0, 0)

fn Parser.parse_continue(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    Parser.advance(self)  // consume 'continue'
    AstPool.add_node(self.pool, NK_CONTINUE(), s, Parser.cur_start(self), 0, 0, 0)

fn Parser.parse_defer(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    Parser.advance(self)  // consume 'defer'
    let inner = Parser.parse_expr(self)
    AstPool.add_node(self.pool, NK_DEFER(), s, Parser.cur_start(self), inner, 0, 0)

fn Parser.parse_labeled_loop(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    // Label token includes the leading '
    let label_text = Parser.token_text(self)
    let label_name = label_text.slice(1, label_text.len())
    let _label_str = AstPool.add_string(self.pool, label_name)
    Parser.advance(self)  // consume label
    if Parser.peek(self) == TK_COLON():
        Parser.advance(self)
    if Parser.peek(self) == TK_KW_FOR():
        return Parser.parse_for(self)
    if Parser.peek(self) == TK_KW_WHILE():
        return Parser.parse_while(self)
    if Parser.peek(self) == TK_KW_LOOP():
        return Parser.parse_loop(self)
    -1

// ── Let binding ────────────────────────────────────────────────

fn Parser.parse_let_binding(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    let is_var = Parser.peek(self) == TK_KW_VAR()
    Parser.advance(self)  // consume let/var

    // Tuple destructure: let (a, b) = expr
    if Parser.peek(self) == TK_L_PAREN():
        Parser.advance(self)
        let extra_start = AstPool.extra_len(self.pool)
        var count = 0
        while Parser.peek(self) != TK_R_PAREN() and Parser.peek(self) != TK_EOF():
            if count > 0:
                if Parser.peek(self) == TK_COMMA():
                    Parser.advance(self)
                    Parser.skip_nl(self)
            if Parser.peek(self) == TK_IDENT():
                let n = Parser.intern(self)
                AstPool.add_extra(self.pool, n)
                Parser.advance(self)
                count = count + 1
        Parser.expect(self, TK_R_PAREN())
        Parser.expect(self, TK_EQ())
        Parser.skip_nl(self)
        let init = Parser.parse_expr(self)
        return AstPool.add_node(self.pool, NK_TUPLE_DESTRUCTURE(), s, Parser.cur_start(self), extra_start, count, init)

    if Parser.peek(self) != TK_IDENT():
        return -1
    let name_str = Parser.intern(self)
    Parser.advance(self)
    var type_node = 0
    if Parser.peek(self) == TK_COLON():
        Parser.advance(self)
        Parser.skip_nl(self)
        type_node = Parser.parse_type_expr(self)
    var init = 0
    if Parser.peek(self) == TK_EQ():
        Parser.advance(self)
        Parser.skip_nl(self)
        init = Parser.parse_expr(self)
    // Check for is_var flag — store in d2 upper bit
    var type_or_flag = type_node
    if is_var:
        type_or_flag = type_node | 0x40000000  // mark as var
    AstPool.add_node(self.pool, NK_LET_BINDING(), s, Parser.cur_start(self), name_str, init, type_or_flag)

// ── Match expression ───────────────────────────────────────────

fn Parser.parse_match_expr(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    Parser.advance(self)  // consume 'match'
    Parser.skip_nl(self)
    let subject = Parser.parse_expr(self)
    Parser.skip_nl(self)
    let arm_count = Parser.parse_match_arms(self)
    let arms_start = AstPool.extra_len(self.pool) - arm_count
    AstPool.add_node(self.pool, NK_MATCH(), s, Parser.cur_start(self), subject, arms_start, arm_count)

fn Parser.parse_match_arms(self: *mut Parser) -> i32:
    var arms = Vec.new()
    // Determine arm column from first arm
    if Parser.peek(self) == TK_EOF() or Parser.peek(self) == TK_NEWLINE():
        Parser.skip_nl(self)
    if Parser.peek(self) == TK_EOF():
        return 0
    let arm_col = column_of(self.source, Parser.cur_start(self))

    loop:
        if Parser.peek(self) == TK_EOF():
            break
        let cur_col = column_of(self.source, Parser.cur_start(self))
        if cur_col < arm_col:
            break
        if not Parser.is_arm_start(self):
            break
        let pattern = Parser.parse_pattern(self)
        // Check for guard: if cond
        var guard = 0
        if Parser.peek(self) == TK_KW_IF():
            Parser.advance(self)
            guard = Parser.parse_expr(self)
        // Expect ->
        Parser.expect(self, TK_ARROW())
        let body = Parser.parse_block_or_expr(self)
        let arm = AstPool.add_node(self.pool, NK_MATCH_ARM(), 0, 0, pattern, body, guard)
        arms.push(arm)
        // Check for next arm
        let saved = self.pos
        Parser.skip_nl(self)
        if Parser.peek(self) == TK_EOF():
            break
        let next_col = column_of(self.source, Parser.cur_start(self))
        if next_col < arm_col:
            self.pos = saved
            break
        if not Parser.is_arm_start(self):
            self.pos = saved
            break
    let arm_count = arms.len() as i32
    var ai = 0
    while ai < arm_count:
        AstPool.add_extra(self.pool, arms.get(ai as i64))
        ai = ai + 1
    arm_count

fn Parser.is_arm_start(self: *mut Parser) -> bool:
    let t = Parser.peek(self)
    t == TK_IDENT() or t == TK_INT_LIT() or t == TK_DOT_IDENT() or t == TK_TRUE() or t == TK_FALSE() or t == TK_STRING_LIT() or t == TK_MINUS() or t == TK_L_PAREN() or t == TK_L_BRACKET()

fn Parser.parse_pattern(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    let tag = Parser.peek(self)
    if tag == TK_INT_LIT():
        let text_str = Parser.intern(self)
        Parser.advance(self)
        return AstPool.add_node(self.pool, NK_PAT_INT(), s, Parser.cur_start(self), text_str, 0, 0)
    if tag == TK_MINUS():
        // Negative int pattern
        Parser.advance(self)
        if Parser.peek(self) == TK_INT_LIT():
            let raw = Parser.token_text(self)
            let neg = "-" ++ raw
            let text_str = AstPool.add_string(self.pool, neg)
            Parser.advance(self)
            return AstPool.add_node(self.pool, NK_PAT_INT(), s, Parser.cur_start(self), text_str, 0, 0)
        return -1
    if tag == TK_TRUE():
        Parser.advance(self)
        return AstPool.add_node(self.pool, NK_PAT_BOOL(), s, Parser.cur_start(self), 1, 0, 0)
    if tag == TK_FALSE():
        Parser.advance(self)
        return AstPool.add_node(self.pool, NK_PAT_BOOL(), s, Parser.cur_start(self), 0, 0, 0)
    if tag == TK_STRING_LIT():
        let raw = Parser.token_text(self)
        var content = raw
        if raw.len() >= 2:
            content = raw.slice(1, raw.len() - 1)
        let str_idx = AstPool.add_string(self.pool, content)
        Parser.advance(self)
        return AstPool.add_node(self.pool, NK_PAT_STRING(), s, Parser.cur_start(self), str_idx, 0, 0)
    if tag == TK_DOT_IDENT():
        // .Variant or .Variant(bindings)
        let text = Parser.token_text(self)
        let name = text.slice(1, text.len())
        let name_str = AstPool.add_string(self.pool, name)
        Parser.advance(self)
        var binds = Vec.new()
        if Parser.peek(self) == TK_L_PAREN():
            Parser.advance(self)
            while Parser.peek(self) != TK_R_PAREN() and Parser.peek(self) != TK_EOF():
                if binds.len() > 0:
                    if Parser.peek(self) == TK_COMMA():
                        Parser.advance(self)
                        Parser.skip_nl(self)
                let sub = Parser.parse_pattern(self)
                binds.push(sub)
            Parser.expect(self, TK_R_PAREN())
        let extra_start = AstPool.extra_len(self.pool)
        let bind_count = binds.len() as i32
        var bi = 0
        while bi < bind_count:
            AstPool.add_extra(self.pool, binds.get(bi as i64))
            bi = bi + 1
        return AstPool.add_node(self.pool, NK_PAT_ENUM_SHORTHAND(), s, Parser.cur_start(self), name_str, extra_start, bind_count)
    if tag == TK_L_PAREN():
        // Tuple pattern
        Parser.advance(self)
        var elems = Vec.new()
        while Parser.peek(self) != TK_R_PAREN() and Parser.peek(self) != TK_EOF():
            if elems.len() > 0:
                if Parser.peek(self) == TK_COMMA():
                    Parser.advance(self)
                    Parser.skip_nl(self)
            let sub = Parser.parse_pattern(self)
            elems.push(sub)
        Parser.expect(self, TK_R_PAREN())
        let extra_start = AstPool.extra_len(self.pool)
        let count = elems.len() as i32
        var ei = 0
        while ei < count:
            AstPool.add_extra(self.pool, elems.get(ei as i64))
            ei = ei + 1
        return AstPool.add_node(self.pool, NK_PAT_TUPLE(), s, Parser.cur_start(self), extra_start, count, 0)
    if tag == TK_IDENT():
        let text = Parser.token_text(self)
        if text == "_":
            Parser.advance(self)
            return AstPool.add_node(self.pool, NK_PAT_WILDCARD(), s, Parser.cur_start(self), 0, 0, 0)
        // Check if uppercase → variant
        if text.len() > 0 and is_upper(text[0]):
            let name_str = Parser.intern(self)
            Parser.advance(self)
            // Check for payload
            var binds = Vec.new()
            if Parser.peek(self) == TK_L_PAREN():
                Parser.advance(self)
                while Parser.peek(self) != TK_R_PAREN() and Parser.peek(self) != TK_EOF():
                    if binds.len() > 0:
                        if Parser.peek(self) == TK_COMMA():
                            Parser.advance(self)
                            Parser.skip_nl(self)
                    let sub = Parser.parse_pattern(self)
                    binds.push(sub)
                Parser.expect(self, TK_R_PAREN())
            let extra_start = AstPool.extra_len(self.pool)
            let bind_count = binds.len() as i32
            var bi = 0
            while bi < bind_count:
                AstPool.add_extra(self.pool, binds.get(bi as i64))
                bi = bi + 1
            return AstPool.add_node(self.pool, NK_PAT_VARIANT(), s, Parser.cur_start(self), name_str, extra_start, bind_count)
        // Variable binding
        let name_str = Parser.intern(self)
        Parser.advance(self)
        return AstPool.add_node(self.pool, NK_PAT_IDENT(), s, Parser.cur_start(self), name_str, 0, 0)
    -1

// ── Array literal ──────────────────────────────────────────────

fn Parser.parse_array_lit(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    Parser.advance(self)  // consume '['
    Parser.skip_nl(self)
    var elems = Vec.new()
    while Parser.peek(self) != TK_R_BRACKET() and Parser.peek(self) != TK_EOF():
        if elems.len() > 0:
            if Parser.peek(self) == TK_COMMA():
                Parser.advance(self)
                Parser.skip_nl(self)
        if Parser.peek(self) == TK_R_BRACKET():
            break
        let elem = Parser.parse_expr(self)
        elems.push(elem)
    let e = Parser.cur_end(self)
    Parser.expect(self, TK_R_BRACKET())
    let extra_start = AstPool.extra_len(self.pool)
    let count = elems.len() as i32
    var ei = 0
    while ei < count:
        AstPool.add_extra(self.pool, elems.get(ei as i64))
        ei = ei + 1
    AstPool.add_node(self.pool, NK_ARRAY_LIT(), s, e, extra_start, count, 0)

// ── Closure ────────────────────────────────────────────────────

fn Parser.parse_closure(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    Parser.advance(self)  // consume '|'
    var param_names = Vec.new()
    var param_types = Vec.new()
    while Parser.peek(self) != TK_PIPE() and Parser.peek(self) != TK_EOF():
        if param_names.len() > 0:
            if Parser.peek(self) == TK_COMMA():
                Parser.advance(self)
                Parser.skip_nl(self)
        if Parser.peek(self) == TK_IDENT():
            let pn = Parser.intern(self)
            Parser.advance(self)
            var pt = 0
            if Parser.peek(self) == TK_COLON():
                Parser.advance(self)
                pt = Parser.parse_type_expr(self)
            param_names.push(pn)
            param_types.push(pt)
    Parser.expect(self, TK_PIPE())
    let body = Parser.parse_expr(self)
    let extra_start = AstPool.extra_len(self.pool)
    let param_count = param_names.len() as i32
    var pi = 0
    while pi < param_count:
        AstPool.add_extra(self.pool, param_names.get(pi as i64))
        AstPool.add_extra(self.pool, param_types.get(pi as i64))
        pi = pi + 1
    AstPool.add_node(self.pool, NK_CLOSURE(), s, Parser.cur_start(self), body, extra_start, param_count)

// ── With expression ────────────────────────────────────────────

fn Parser.parse_with_expr(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    Parser.advance(self)  // consume 'with'
    self.suppress_as = true
    let source = Parser.parse_expr(self)
    self.suppress_as = false
    if Parser.peek(self) != TK_KW_AS():
        // with expr: body (form 2 — builder)
        if Parser.peek(self) == TK_COLON():
            Parser.advance(self)
        let body = Parser.parse_block_or_expr(self)
        return AstPool.add_node(self.pool, NK_WITH_EXPR(), s, Parser.cur_start(self), source, 0, body)
    Parser.advance(self)  // consume 'as'
    // Optional 'mut'
    if Parser.peek(self) == TK_KW_MUT():
        Parser.advance(self)
    if Parser.peek(self) != TK_IDENT():
        return -1
    let name_str = Parser.intern(self)
    Parser.advance(self)
    if Parser.peek(self) == TK_COLON():
        Parser.advance(self)
    let body = Parser.parse_block_or_expr(self)
    AstPool.add_node(self.pool, NK_WITH_EXPR(), s, Parser.cur_start(self), source, name_str, body)

// ── Record update ──────────────────────────────────────────────

fn Parser.parse_record_update(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    Parser.advance(self)  // consume '{'
    Parser.skip_nl(self)
    let source = Parser.parse_expr(self)
    // Expect 'with' keyword
    if not Parser.is_ident_named(self, "with") and Parser.peek(self) != TK_KW_WITH():
        // Not a record update — treat as error
        while Parser.peek(self) != TK_R_BRACE() and Parser.peek(self) != TK_EOF():
            Parser.advance(self)
        Parser.expect(self, TK_R_BRACE())
        return -1
    Parser.advance(self)  // consume 'with'
    Parser.skip_nl(self)
    var field_names = Vec.new()
    var field_vals = Vec.new()
    while Parser.peek(self) != TK_R_BRACE() and Parser.peek(self) != TK_EOF():
        if field_names.len() > 0:
            if Parser.peek(self) == TK_COMMA():
                Parser.advance(self)
                Parser.skip_nl(self)
        if Parser.peek(self) == TK_R_BRACE():
            break
        if Parser.peek(self) != TK_IDENT():
            break
        let f_name = Parser.intern(self)
        Parser.advance(self)
        var f_val = 0
        if Parser.peek(self) == TK_COLON():
            Parser.advance(self)
            Parser.skip_nl(self)
            f_val = Parser.parse_expr(self)
        if f_val == 0:
            f_val = AstPool.add_node(self.pool, NK_IDENT(), 0, 0, f_name, 0, 0)
        field_names.push(f_name)
        field_vals.push(f_val)
        Parser.skip_nl(self)
    Parser.expect(self, TK_R_BRACE())
    let extra_start = AstPool.extra_len(self.pool)
    let field_count = field_names.len() as i32
    var fi = 0
    while fi < field_count:
        AstPool.add_extra(self.pool, field_names.get(fi as i64))
        AstPool.add_extra(self.pool, field_vals.get(fi as i64))
        fi = fi + 1
    AstPool.add_node(self.pool, NK_RECORD_UPDATE(), s, Parser.cur_start(self), source, extra_start, field_count)

// ── Block parsing ──────────────────────────────────────────────

fn Parser.parse_block_or_expr(self: *mut Parser) -> i32:
    // Inline body: no newline
    if Parser.peek(self) != TK_NEWLINE():
        return Parser.parse_expr(self)
    // Multi-line block
    Parser.skip_nl(self)
    if Parser.peek(self) == TK_EOF():
        return 0
    let block_col = column_of(self.source, Parser.cur_start(self))
    var last = Parser.parse_expr(self)
    var stmts = Vec.new()
    loop:
        if Parser.peek(self) != TK_NEWLINE() and Parser.peek(self) != TK_EOF():
            break
        if Parser.peek(self) == TK_EOF():
            break
        let saved = self.pos
        Parser.skip_nl(self)
        if Parser.peek(self) == TK_EOF():
            break
        let next_col = column_of(self.source, Parser.cur_start(self))
        if next_col < block_col:
            self.pos = saved
            break
        // Previous expr was a statement
        stmts.push(last)
        last = Parser.parse_expr(self)
    if stmts.len() == 0:
        return last
    let stmts_start = AstPool.extra_len(self.pool)
    let stmt_count = stmts.len() as i32
    var si = 0
    while si < stmt_count:
        AstPool.add_extra(self.pool, stmts.get(si as i64))
        si = si + 1
    // Build block node
    let s = AstPool.get_start(self.pool, stmts.get(0))
    let e = Parser.cur_start(self)
    AstPool.add_node(self.pool, NK_BLOCK(), s, e, stmts_start, stmt_count, last)

// ── Type expression parsing ────────────────────────────────────

fn Parser.parse_type_expr(self: *mut Parser) -> i32:
    let s = Parser.cur_start(self)
    let tag = Parser.peek(self)
    // &[mut] T — reference type
    if tag == TK_AMPERSAND():
        Parser.advance(self)
        var is_mut = 0
        if Parser.peek(self) == TK_KW_MUT():
            is_mut = 1
            Parser.advance(self)
        let inner = Parser.parse_type_expr(self)
        return AstPool.add_node(self.pool, NK_TYPE_REF(), s, Parser.cur_start(self), inner, is_mut, 0)
    // *[mut|const] T — pointer type
    if tag == TK_STAR():
        Parser.advance(self)
        var is_mut = 0
        if Parser.peek(self) == TK_KW_MUT():
            is_mut = 1
            Parser.advance(self)
        // 'const' is not a keyword, check as ident
        if Parser.is_ident_named(self, "const"):
            Parser.advance(self)
        let inner = Parser.parse_type_expr(self)
        return AstPool.add_node(self.pool, NK_TYPE_PTR(), s, Parser.cur_start(self), inner, is_mut, 0)
    // ?T — optional type
    if tag == TK_QUESTION():
        Parser.advance(self)
        let inner = Parser.parse_type_expr(self)
        return AstPool.add_node(self.pool, NK_TYPE_OPTIONAL(), s, Parser.cur_start(self), inner, 0, 0)
    // (T1, T2) — tuple type
    if tag == TK_L_PAREN():
        Parser.advance(self)
        var elems = Vec.new()
        while Parser.peek(self) != TK_R_PAREN() and Parser.peek(self) != TK_EOF():
            if elems.len() > 0:
                if Parser.peek(self) == TK_COMMA():
                    Parser.advance(self)
                    Parser.skip_nl(self)
            let t = Parser.parse_type_expr(self)
            elems.push(t)
        Parser.expect(self, TK_R_PAREN())
        let extra_start = AstPool.extra_len(self.pool)
        let count = elems.len() as i32
        var ei = 0
        while ei < count:
            AstPool.add_extra(self.pool, elems.get(ei as i64))
            ei = ei + 1
        return AstPool.add_node(self.pool, NK_TYPE_TUPLE(), s, Parser.cur_start(self), extra_start, count, 0)
    // fn(T1, T2) -> R — function type
    if tag == TK_KW_FN():
        Parser.advance(self)
        var params = Vec.new()
        if Parser.peek(self) == TK_L_PAREN():
            Parser.advance(self)
            while Parser.peek(self) != TK_R_PAREN() and Parser.peek(self) != TK_EOF():
                if params.len() > 0:
                    if Parser.peek(self) == TK_COMMA():
                        Parser.advance(self)
                        Parser.skip_nl(self)
                let pt = Parser.parse_type_expr(self)
                params.push(pt)
            Parser.expect(self, TK_R_PAREN())
        var ret = 0
        if Parser.peek(self) == TK_ARROW():
            Parser.advance(self)
            Parser.skip_nl(self)
            ret = Parser.parse_type_expr(self)
        let extra_start = AstPool.extra_len(self.pool)
        let param_count = params.len() as i32
        var pi = 0
        while pi < param_count:
            AstPool.add_extra(self.pool, params.get(pi as i64))
            pi = pi + 1
        return AstPool.add_node(self.pool, NK_TYPE_FN(), s, Parser.cur_start(self), extra_start, param_count, ret)
    // [N]T — array type or []T — slice type
    if tag == TK_L_BRACKET():
        Parser.advance(self)
        if Parser.peek(self) == TK_R_BRACKET():
            // []T — slice
            Parser.advance(self)
            let elem = Parser.parse_type_expr(self)
            return AstPool.add_node(self.pool, NK_TYPE_SLICE(), s, Parser.cur_start(self), elem, 0, 0)
        // [N]T — array
        let size_str = Parser.intern(self)
        Parser.advance(self)
        Parser.expect(self, TK_R_BRACKET())
        let elem = Parser.parse_type_expr(self)
        return AstPool.add_node(self.pool, NK_TYPE_ARRAY(), s, Parser.cur_start(self), size_str, elem, 0)
    // dyn Trait — trait object
    if tag == TK_KW_DYN():
        Parser.advance(self)
        if Parser.peek(self) == TK_IDENT():
            let name_str = Parser.intern(self)
            Parser.advance(self)
            return AstPool.add_node(self.pool, NK_TYPE_TRAIT_OBJ(), s, Parser.cur_start(self), name_str, 0, 0)
        return -1
    // Named type or generic: TypeName or TypeName[T, U]
    if tag == TK_IDENT():
        let name_str = Parser.intern(self)
        Parser.advance(self)
        if Parser.peek(self) == TK_L_BRACKET():
            // Generic: Name[T, U]
            Parser.advance(self)
            var args = Vec.new()
            while Parser.peek(self) != TK_R_BRACKET() and Parser.peek(self) != TK_EOF():
                if args.len() > 0:
                    if Parser.peek(self) == TK_COMMA():
                        Parser.advance(self)
                        Parser.skip_nl(self)
                let t = Parser.parse_type_expr(self)
                args.push(t)
            Parser.expect(self, TK_R_BRACKET())
            let extra_start = AstPool.extra_len(self.pool)
            let count = args.len() as i32
            var ai = 0
            while ai < count:
                AstPool.add_extra(self.pool, args.get(ai as i64))
                ai = ai + 1
            return AstPool.add_node(self.pool, NK_TYPE_GENERIC(), s, Parser.cur_start(self), name_str, extra_start, count)
        return AstPool.add_node(self.pool, NK_TYPE_NAMED(), s, Parser.cur_start(self), name_str, 0, 0)
    // Inferred
    AstPool.add_node(self.pool, NK_TYPE_INFERRED(), s, s, 0, 0, 0)

// ── Error recovery ─────────────────────────────────────────────

fn Parser.recover_to_top_level(self: *mut Parser) -> void:
    while Parser.peek(self) != TK_EOF():
        let t = Parser.peek(self)
        if t == TK_KW_FN() or t == TK_KW_TYPE() or t == TK_KW_USE() or t == TK_KW_LET() or t == TK_KW_VAR() or t == TK_KW_PUB() or t == TK_KW_EXTERN() or t == TK_KW_IMPL() or t == TK_KW_TRAIT():
            return
        Parser.advance(self)
