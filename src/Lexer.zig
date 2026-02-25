//! Tokenizer: source bytes → token stream.
//!
//! The lexer scans UTF-8 source text and produces a flat list of tokens
//! with source spans.  Whitespace (except significant newlines) is
//! consumed silently.  Comments are preserved as tokens for the future
//! formatter / CST.

const std = @import("std");
const Token = @import("Token.zig");
const Span = @import("Span.zig");
const Diagnostic = @import("Diagnostic.zig");

const Lexer = @This();

source: []const u8,
pos: u32,
file_id: Span.FileId,
diagnostics: *Diagnostic.DiagnosticList,

pub fn init(source: []const u8, file_id: Span.FileId, diagnostics: *Diagnostic.DiagnosticList) Lexer {
    return .{
        .source = source,
        .pos = 0,
        .file_id = file_id,
        .diagnostics = diagnostics,
    };
}

/// Tokenize the entire source, returning a token list ending with `.eof`.
pub fn tokenize(self: *Lexer, allocator: std.mem.Allocator) !Token.List {
    var tokens = Token.List.init(allocator);
    while (true) {
        const tok = self.next();
        try tokens.append(tok);
        if (tok.tag == .eof) break;
    }
    return tokens;
}

/// Produce the next token, advancing the cursor.
pub fn next(self: *Lexer) Token {
    self.skipWhitespace();

    if (self.pos >= self.source.len) {
        return self.makeToken(.eof, self.pos, self.pos);
    }

    const start = self.pos;
    const ch = self.source[self.pos];

    switch (ch) {
        '\n' => {
            self.pos += 1;
            return self.makeToken(.newline, start, self.pos);
        },
        '(' => return self.single(.l_paren),
        ')' => return self.single(.r_paren),
        '[' => return self.single(.l_bracket),
        ']' => return self.single(.r_bracket),
        '{' => return self.single(.l_brace),
        '}' => return self.single(.r_brace),
        ',' => return self.single(.comma),
        ';' => return self.single(.semicolon),
        ':' => return self.single(.colon),
        '~' => return self.single(.tilde),
        '@' => return self.single(.at),
        '^' => return self.single(.caret),
        '&' => return self.single(.ampersand),

        '+' => return self.operatorOrCompound(start, &.{
            .{ '%', .plus_wrap },
            .{ '=', .plus_eq },
        }, .plus),
        '-' => return self.operatorOrCompound(start, &.{
            .{ '>', .arrow },
            .{ '%', .minus_wrap },
            .{ '=', .minus_eq },
        }, .minus),
        '*' => return self.operatorOrCompound(start, &.{
            .{ '%', .star_wrap },
            .{ '=', .star_eq },
        }, .star),
        '%' => return self.operatorOrCompound(start, &.{
            .{ '=', .percent_eq },
        }, .percent),
        '=' => return self.operatorOrCompound(start, &.{
            .{ '=', .eq_eq },
            .{ '>', .fat_arrow },
        }, .eq),
        '!' => return self.operatorOrCompound(start, &.{
            .{ '=', .bang_eq },
        }, .invalid),
        '?' => return self.operatorOrCompound(start, &.{
            .{ '.', .question_dot },
            .{ '?', .question_question },
        }, .question),

        '<' => {
            self.pos += 1;
            if (self.pos < self.source.len) {
                switch (self.source[self.pos]) {
                    '=' => {
                        self.pos += 1;
                        return self.makeToken(.lt_eq, start, self.pos);
                    },
                    '<' => {
                        self.pos += 1;
                        return self.makeToken(.lt_lt, start, self.pos);
                    },
                    '|' => {
                        self.pos += 1;
                        return self.makeToken(.lt_pipe, start, self.pos);
                    },
                    else => {},
                }
            }
            return self.makeToken(.lt, start, self.pos);
        },
        '>' => {
            self.pos += 1;
            if (self.pos < self.source.len) {
                switch (self.source[self.pos]) {
                    '=' => {
                        self.pos += 1;
                        return self.makeToken(.gt_eq, start, self.pos);
                    },
                    '>' => {
                        self.pos += 1;
                        return self.makeToken(.gt_gt, start, self.pos);
                    },
                    else => {},
                }
            }
            return self.makeToken(.gt, start, self.pos);
        },

        '|' => {
            self.pos += 1;
            if (self.pos < self.source.len and self.source[self.pos] == '>') {
                self.pos += 1;
                return self.makeToken(.pipe_gt, start, self.pos);
            }
            return self.makeToken(.pipe, start, self.pos);
        },

        '/' => {
            self.pos += 1;
            if (self.pos < self.source.len) {
                switch (self.source[self.pos]) {
                    '/' => return self.lexComment(start),
                    '=' => {
                        self.pos += 1;
                        return self.makeToken(.slash_eq, start, self.pos);
                    },
                    else => {},
                }
            }
            return self.makeToken(.slash, start, self.pos);
        },

        '.' => {
            self.pos += 1;
            if (self.pos < self.source.len) {
                switch (self.source[self.pos]) {
                    '.' => {
                        self.pos += 1;
                        if (self.pos < self.source.len and self.source[self.pos] == '=') {
                            self.pos += 1;
                            return self.makeToken(.dot_dot_eq, start, self.pos);
                        }
                        if (self.pos < self.source.len and self.source[self.pos] == '.') {
                            self.pos += 1;
                            return self.makeToken(.dot_dot_dot, start, self.pos);
                        }
                        return self.makeToken(.dot_dot, start, self.pos);
                    },
                    'A'...'Z' => return self.lexDotIdentifier(start),
                    else => {},
                }
            }
            return self.makeToken(.dot, start, self.pos);
        },

        '"' => return self.lexString(start),

        '0'...'9' => return self.lexNumber(start),

        'a'...'z', 'A'...'Z', '_' => return self.lexIdentifierOrKeyword(start),

        else => {
            self.pos += 1;
            self.diagnostics.emit(Diagnostic.err("unexpected character", self.spanFrom(start, self.pos)));
            return self.makeToken(.invalid, start, self.pos);
        },
    }
}

// --- Internal helpers ---

fn single(self: *Lexer, tag: Token.Tag) Token {
    const start = self.pos;
    self.pos += 1;
    return self.makeToken(tag, start, self.pos);
}

const Pair = struct { u8, Token.Tag };

fn operatorOrCompound(self: *Lexer, start: u32, pairs: []const Pair, default_tag: Token.Tag) Token {
    self.pos += 1;
    if (self.pos < self.source.len) {
        for (pairs) |pair| {
            if (self.source[self.pos] == pair[0]) {
                self.pos += 1;
                return self.makeToken(pair[1], start, self.pos);
            }
        }
    }
    if (default_tag == .invalid) {
        self.diagnostics.emit(Diagnostic.err("unexpected character", self.spanFrom(start, self.pos)));
    }
    return self.makeToken(default_tag, start, self.pos);
}

fn lexComment(self: *Lexer, start: u32) Token {
    while (self.pos < self.source.len and self.source[self.pos] != '\n') {
        self.pos += 1;
    }
    return self.makeToken(.comment, start, self.pos);
}

fn lexDotIdentifier(self: *Lexer, start: u32) Token {
    while (self.pos < self.source.len and isIdentContinue(self.source[self.pos])) {
        self.pos += 1;
    }
    return self.makeToken(.dot_identifier, start, self.pos);
}

fn lexString(self: *Lexer, start: u32) Token {
    self.pos += 1; // skip opening "

    // Check for triple-quoted multi-line string: """..."""
    if (self.pos + 1 < self.source.len and self.source[self.pos] == '"' and self.source[self.pos + 1] == '"') {
        self.pos += 2; // skip the two additional quotes
        // Skip optional leading newline after opening """
        if (self.pos < self.source.len and self.source[self.pos] == '\n') {
            self.pos += 1;
        }
        while (self.pos + 2 < self.source.len) {
            if (self.source[self.pos] == '"' and self.source[self.pos + 1] == '"' and self.source[self.pos + 2] == '"') {
                self.pos += 3;
                return self.makeToken(.string_literal, start, self.pos);
            }
            if (self.source[self.pos] == '\\') {
                self.pos += 1; // skip escape char
            }
            self.pos += 1;
        }
        self.diagnostics.emit(Diagnostic.err("unterminated multi-line string", self.spanFrom(start, self.pos)));
        return self.makeToken(.string_literal, start, self.pos);
    }

    while (self.pos < self.source.len) {
        const ch = self.source[self.pos];
        if (ch == '"') {
            self.pos += 1;
            return self.makeToken(.string_literal, start, self.pos);
        }
        if (ch == '\\') {
            self.pos += 1; // skip escape char
        }
        self.pos += 1;
    }
    self.diagnostics.emit(Diagnostic.err("unterminated string literal", self.spanFrom(start, self.pos)));
    return self.makeToken(.string_literal, start, self.pos);
}

fn lexNumber(self: *Lexer, start: u32) Token {
    var is_float = false;
    // Check for 0x, 0b, 0o prefixes
    if (self.source[self.pos] == '0' and self.pos + 1 < self.source.len) {
        const prefix = self.source[self.pos + 1];
        if (prefix == 'x' or prefix == 'X') {
            self.pos += 2; // skip '0x'
            while (self.pos < self.source.len and (std.ascii.isHex(self.source[self.pos]) or self.source[self.pos] == '_')) {
                self.pos += 1;
            }
            return self.makeToken(.int_literal, start, self.pos);
        }
        if (prefix == 'b' or prefix == 'B') {
            self.pos += 2; // skip '0b'
            while (self.pos < self.source.len and (self.source[self.pos] == '0' or self.source[self.pos] == '1' or self.source[self.pos] == '_')) {
                self.pos += 1;
            }
            return self.makeToken(.int_literal, start, self.pos);
        }
        if (prefix == 'o' or prefix == 'O') {
            self.pos += 2; // skip '0o'
            while (self.pos < self.source.len and (self.source[self.pos] >= '0' and self.source[self.pos] <= '7' or self.source[self.pos] == '_')) {
                self.pos += 1;
            }
            return self.makeToken(.int_literal, start, self.pos);
        }
    }
    while (self.pos < self.source.len and (std.ascii.isDigit(self.source[self.pos]) or self.source[self.pos] == '_')) {
        self.pos += 1;
    }
    // Check for decimal point (but not `..` range operator).
    if (self.pos < self.source.len and self.source[self.pos] == '.') {
        if (self.pos + 1 < self.source.len and self.source[self.pos + 1] != '.') {
            is_float = true;
            self.pos += 1;
            while (self.pos < self.source.len and (std.ascii.isDigit(self.source[self.pos]) or self.source[self.pos] == '_')) {
                self.pos += 1;
            }
        }
    }
    return self.makeToken(if (is_float) .float_literal else .int_literal, start, self.pos);
}

fn lexIdentifierOrKeyword(self: *Lexer, start: u32) Token {
    while (self.pos < self.source.len and isIdentContinue(self.source[self.pos])) {
        self.pos += 1;
    }
    const text = self.source[start..self.pos];
    if (Token.Tag.fromKeyword(text)) |kw| {
        return self.makeToken(kw, start, self.pos);
    }
    return self.makeToken(.identifier, start, self.pos);
}

fn skipWhitespace(self: *Lexer) void {
    while (self.pos < self.source.len) {
        switch (self.source[self.pos]) {
            ' ', '\t', '\r' => self.pos += 1,
            else => return,
        }
    }
}

fn isIdentContinue(ch: u8) bool {
    return std.ascii.isAlphanumeric(ch) or ch == '_';
}

/// Compute the 0-based column of a byte offset by scanning backward for a newline.
pub fn columnOf(source: []const u8, pos: u32) u32 {
    var p = pos;
    while (p > 0) {
        p -= 1;
        if (source[p] == '\n') {
            return pos - p - 1;
        }
    }
    return pos;
}

fn makeToken(self: *const Lexer, tag: Token.Tag, start: u32, end: u32) Token {
    return .{
        .tag = tag,
        .span = self.spanFrom(start, end),
    };
}

fn spanFrom(self: *const Lexer, start: u32, end: u32) Span {
    return .{ .file = self.file_id, .start = start, .end = end };
}

// --- Tests ---

test "lex simple function" {
    const source = "fn main() -> i32 = 42";
    var diags = Diagnostic.DiagnosticList.init(std.testing.allocator);
    defer diags.deinit();
    var lexer = Lexer.init(source, 0, &diags);
    var tokens = try lexer.tokenize(std.testing.allocator);
    defer tokens.deinit();

    // fn main ( ) -> i32 = 42 eof
    try std.testing.expectEqual(Token.Tag.kw_fn, tokens.tags.items[0]);
    try std.testing.expectEqual(Token.Tag.identifier, tokens.tags.items[1]);
    try std.testing.expectEqual(Token.Tag.l_paren, tokens.tags.items[2]);
    try std.testing.expectEqual(Token.Tag.r_paren, tokens.tags.items[3]);
    try std.testing.expectEqual(Token.Tag.arrow, tokens.tags.items[4]);
    try std.testing.expectEqual(Token.Tag.identifier, tokens.tags.items[5]); // i32
    try std.testing.expectEqual(Token.Tag.eq, tokens.tags.items[6]);
    try std.testing.expectEqual(Token.Tag.int_literal, tokens.tags.items[7]);
    try std.testing.expectEqual(Token.Tag.eof, tokens.tags.items[8]);
    try std.testing.expect(!diags.hasErrors());
}
