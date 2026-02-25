//! Token definitions for the With language.
//!
//! The lexer produces a flat list of `Token` values. Each token carries
//! a `Tag` discriminant and a `Span` pointing back into the source text.
//! Literal values and identifier text are recovered from the source via
//! the span — we do not store copies in the token itself.

const std = @import("std");
const Span = @import("Span.zig");

const Token = @This();

tag: Tag,
span: Span,

/// All token kinds produced by the lexer.
pub const Tag = enum(u8) {
    // -- Literals --
    int_literal,
    float_literal,
    string_literal,
    string_start, // opening `"` of an interpolated string
    string_end, // closing `"` of an interpolated string
    string_fragment, // literal text between interpolation holes
    char_literal,
    true_literal,
    false_literal,

    // -- Identifiers --
    identifier,
    dot_identifier, // .Variant (enum shorthand)

    // -- Keywords --
    kw_fn,
    kw_let,
    kw_var,
    kw_if,
    kw_else,
    kw_then,
    kw_match,
    kw_for,
    kw_in,
    kw_while,
    kw_loop,
    kw_return,
    kw_break,
    kw_continue,
    kw_with,
    kw_as,
    kw_mut,
    kw_type,
    kw_trait,
    kw_impl,
    kw_extend,
    kw_dyn,
    kw_use,
    kw_module,
    kw_pub,
    kw_async,
    kw_await,
    kw_spawn,
    kw_unsafe,
    kw_comptime,
    kw_gen,
    kw_yield,
    kw_defer,
    kw_error,
    kw_extern,
    kw_c_import,
    kw_ephemeral,
    kw_select,
    kw_not,
    kw_and,
    kw_or,

    // -- Operators --
    plus, // +
    minus, // -
    star, // *
    slash, // /
    percent, // %
    plus_wrap, // +%
    minus_wrap, // -%
    star_wrap, // *%
    eq, // =
    eq_eq, // ==
    bang_eq, // !=
    lt, // <
    gt, // >
    lt_eq, // <=
    gt_eq, // >=
    ampersand, // &
    pipe, // |
    caret, // ^
    tilde, // ~
    at, // @
    question, // ?
    question_dot, // ?.
    question_question, // ??
    arrow, // ->
    fat_arrow, // =>
    dot_dot, // ..
    dot_dot_eq, // ..=
    dot_dot_dot, // ...
    pipe_gt, // |>
    lt_pipe, // <|
    gt_gt, // >>
    lt_lt, // <<
    plus_eq, // +=
    minus_eq, // -=
    star_eq, // *=
    slash_eq, // /=
    percent_eq, // %=

    // -- Delimiters --
    l_paren, // (
    r_paren, // )
    l_bracket, // [
    r_bracket, // ]
    l_brace, // {
    r_brace, // }

    // -- Punctuation --
    colon, // :
    comma, // ,
    dot, // .
    semicolon, // ;

    // -- Structural --
    newline, // significant newline (statement separator)
    indent, // indentation increase (future: indentation-sensitive parsing)
    dedent, // indentation decrease

    // -- Special --
    comment, // // line comment
    eof,
    invalid,

    /// Lookup table: keyword string → Tag.  Returns `null` if not a keyword.
    pub fn fromKeyword(str: []const u8) ?Tag {
        const map = std.StaticStringMap(Tag).initComptime(.{
            .{ "fn", .kw_fn },
            .{ "let", .kw_let },
            .{ "var", .kw_var },
            .{ "if", .kw_if },
            .{ "else", .kw_else },
            .{ "then", .kw_then },
            .{ "match", .kw_match },
            .{ "for", .kw_for },
            .{ "in", .kw_in },
            .{ "while", .kw_while },
            .{ "loop", .kw_loop },
            .{ "return", .kw_return },
            .{ "break", .kw_break },
            .{ "continue", .kw_continue },
            .{ "with", .kw_with },
            .{ "as", .kw_as },
            .{ "mut", .kw_mut },
            .{ "type", .kw_type },
            .{ "trait", .kw_trait },
            .{ "impl", .kw_impl },
            .{ "extend", .kw_extend },
            .{ "dyn", .kw_dyn },
            .{ "use", .kw_use },
            .{ "module", .kw_module },
            .{ "pub", .kw_pub },
            .{ "async", .kw_async },
            .{ "await", .kw_await },
            .{ "spawn", .kw_spawn },
            .{ "unsafe", .kw_unsafe },
            .{ "comptime", .kw_comptime },
            .{ "gen", .kw_gen },
            .{ "yield", .kw_yield },
            .{ "defer", .kw_defer },
            .{ "error", .kw_error },
            .{ "extern", .kw_extern },
            .{ "c_import", .kw_c_import },
            .{ "ephemeral", .kw_ephemeral },
            .{ "select", .kw_select },
            .{ "true", .true_literal },
            .{ "false", .false_literal },
            .{ "not", .kw_not },
            .{ "and", .kw_and },
            .{ "or", .kw_or },
        });
        return map.get(str);
    }

    /// Returns a human-readable name for this token tag (for diagnostics).
    pub fn name(self: Tag) []const u8 {
        return switch (self) {
            .int_literal => "integer literal",
            .float_literal => "float literal",
            .string_literal => "string literal",
            .string_start => "string start",
            .string_end => "string end",
            .string_fragment => "string fragment",
            .char_literal => "character literal",
            .true_literal => "'true'",
            .false_literal => "'false'",
            .identifier => "identifier",
            .dot_identifier => "dot-identifier",
            .kw_fn => "'fn'",
            .kw_let => "'let'",
            .kw_var => "'var'",
            .kw_if => "'if'",
            .kw_else => "'else'",
            .kw_then => "'then'",
            .kw_match => "'match'",
            .kw_for => "'for'",
            .kw_in => "'in'",
            .kw_while => "'while'",
            .kw_loop => "'loop'",
            .kw_return => "'return'",
            .kw_break => "'break'",
            .kw_continue => "'continue'",
            .kw_with => "'with'",
            .kw_as => "'as'",
            .kw_mut => "'mut'",
            .kw_type => "'type'",
            .kw_trait => "'trait'",
            .kw_impl => "'impl'",
            .kw_extend => "'extend'",
            .kw_dyn => "'dyn'",
            .kw_use => "'use'",
            .kw_module => "'module'",
            .kw_pub => "'pub'",
            .kw_async => "'async'",
            .kw_await => "'await'",
            .kw_spawn => "'spawn'",
            .kw_unsafe => "'unsafe'",
            .kw_comptime => "'comptime'",
            .kw_gen => "'gen'",
            .kw_yield => "'yield'",
            .kw_defer => "'defer'",
            .kw_error => "'error'",
            .kw_extern => "'extern'",
            .kw_c_import => "'c_import'",
            .kw_ephemeral => "'ephemeral'",
            .kw_select => "'select'",
            .kw_not => "'not'",
            .kw_and => "'and'",
            .kw_or => "'or'",
            .plus => "'+'",
            .minus => "'-'",
            .star => "'*'",
            .slash => "'/'",
            .percent => "'%'",
            .plus_wrap => "'+%'",
            .minus_wrap => "'-%'",
            .star_wrap => "'*%'",
            .eq => "'='",
            .eq_eq => "'=='",
            .bang_eq => "'!='",
            .lt => "'<'",
            .gt => "'>'",
            .lt_eq => "'<='",
            .gt_eq => "'>='",
            .ampersand => "'&'",
            .pipe => "'|'",
            .caret => "'^'",
            .tilde => "'~'",
            .at => "'@'",
            .question => "'?'",
            .question_dot => "'?.'",
            .question_question => "'??'",
            .arrow => "'->'",
            .fat_arrow => "'=>'",
            .dot_dot => "'..'",
            .dot_dot_eq => "'..='",
            .dot_dot_dot => "'...'",
            .pipe_gt => "'|>'",
            .lt_pipe => "'<|'",
            .gt_gt => "'>>'",
            .lt_lt => "'<<'",
            .plus_eq => "'+='",
            .minus_eq => "'-='",
            .star_eq => "'*='",
            .slash_eq => "'/='",
            .percent_eq => "'%='",
            .l_paren => "'('",
            .r_paren => "')'",
            .l_bracket => "'['",
            .r_bracket => "']'",
            .l_brace => "'{'",
            .r_brace => "'}'",
            .colon => "':'",
            .comma => "','",
            .dot => "'.'",
            .semicolon => "';'",
            .newline => "newline",
            .indent => "indent",
            .dedent => "dedent",
            .comment => "comment",
            .eof => "end of file",
            .invalid => "invalid token",
        };
    }
};

/// A growable list of tokens stored as parallel arrays for cache-friendly
/// iteration over tags alone (the common case during parsing).
pub const List = struct {
    tags: std.ArrayList(Tag),
    spans: std.ArrayList(Span),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) List {
        return .{
            .tags = .empty,
            .spans = .empty,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *List) void {
        self.tags.deinit(self.allocator);
        self.spans.deinit(self.allocator);
    }

    pub fn append(self: *List, token: Token) !void {
        try self.tags.append(self.allocator, token.tag);
        try self.spans.append(self.allocator, token.span);
    }

    pub fn len(self: *const List) usize {
        return self.tags.items.len;
    }

    pub fn get(self: *const List, index: usize) Token {
        return .{
            .tag = self.tags.items[index],
            .span = self.spans.items[index],
        };
    }
};
