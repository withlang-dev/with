// Lexer — Tokenizer: source bytes to token stream.
//
// The lexer scans source text character-by-character and produces
// a flat list of tokens with source spans. Whitespace (except
// significant newlines) is consumed silently. Comments are skipped.

use Token
use Span

// Named character constants for readability.
enum CharCode: i32:
    CH_NEWLINE = 10
    CH_CR = 13
    CH_TAB = 9
    CH_SPACE = 32
    CH_DQUOTE = 34
    CH_SQUOTE = 39
    CH_BACKSLASH = 92
    CH_LBRACE = 123
    CH_RBRACE = 125
    CH_LPAREN = 40
    CH_RPAREN = 41
    CH_LBRACKET = 91
    CH_RBRACKET = 93
    CH_COMMA = 44
    CH_SEMICOLON = 59
    CH_COLON = 58
    CH_TILDE = 126
    CH_AT = 64
    CH_CARET = 94
    CH_AMPERSAND = 38
    CH_PLUS = 43
    CH_MINUS = 45
    CH_STAR = 42
    CH_PERCENT = 37
    CH_EQ = 61
    CH_BANG = 33
    CH_QUESTION = 63
    CH_LT = 60
    CH_GT = 62
    CH_PIPE = 124
    CH_SLASH = 47
    CH_DOT = 46
    CH_HASH = 35
    CH_UNDERSCORE = 95
    CH_0 = 48
    CH_1 = 49
    CH_7 = 55
    CH_9 = 57
    CH_A = 65
    CH_B = 66
    CH_E = 69
    CH_F = 70
    CH_O = 79
    CH_X = 88
    CH_Z = 90
    CH_a = 97
    CH_b = 98
    CH_e = 101
    CH_f = 102
    CH_i = 105
    CH_n = 110
    CH_o = 111
    CH_r = 114
    CH_t = 116
    CH_u = 117
    CH_x = 120
    CH_z = 122

type Lexer {
    source: str,
    pos: i32,
    file_id: i32,
    token_start: i32,
}

fn Lexer.init(source: str, file_id: i32) -> Lexer:
    Lexer { source, pos: 0, file_id, token_start: 0 }

// Tokenize the entire source, returning a token list ending with EOF.
fn Lexer.tokenize(self: Lexer) -> TokenList:
    var tokens = TokenList.new()
    loop:
        let tag = self.next_token()
        tokens.append(tag, self.token_start, self.pos)
        if tag == TokenKind.TK_EOF:
            break
    tokens

// Produce the next token. Sets token_start/pos and returns the tag.
fn Lexer.next_token(self: Lexer) -> i32:
    self.skip_whitespace()

    let src = self.source
    let slen = src.len() as i32

    self.token_start = self.pos

    if self.pos >= slen:
        return TokenKind.TK_EOF

    let ch = src.byte_at((self.pos) as i64)

    // Newline
    if ch == CharCode.CH_NEWLINE:
        self.pos = self.pos + 1
        return TokenKind.TK_NEWLINE

    // Single-character delimiters and punctuation
    if ch == CharCode.CH_LPAREN:
        self.pos = self.pos + 1
        return TokenKind.TK_L_PAREN
    if ch == CharCode.CH_RPAREN:
        self.pos = self.pos + 1
        return TokenKind.TK_R_PAREN
    if ch == CharCode.CH_LBRACKET:
        self.pos = self.pos + 1
        return TokenKind.TK_L_BRACKET
    if ch == CharCode.CH_RBRACKET:
        self.pos = self.pos + 1
        return TokenKind.TK_R_BRACKET
    if ch == CharCode.CH_LBRACE:
        self.pos = self.pos + 1
        return TokenKind.TK_L_BRACE
    if ch == CharCode.CH_RBRACE:
        self.pos = self.pos + 1
        return TokenKind.TK_R_BRACE
    if ch == CharCode.CH_COMMA:
        self.pos = self.pos + 1
        return TokenKind.TK_COMMA
    if ch == CharCode.CH_SEMICOLON:
        self.pos = self.pos + 1
        return TokenKind.TK_SEMICOLON
    if ch == CharCode.CH_COLON:
        self.pos = self.pos + 1
        return TokenKind.TK_COLON
    if ch == CharCode.CH_TILDE:
        self.pos = self.pos + 1
        return TokenKind.TK_TILDE
    if ch == CharCode.CH_AT:
        self.pos = self.pos + 1
        return TokenKind.TK_AT
    if ch == CharCode.CH_CARET:
        self.pos = self.pos + 1
        if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.CH_EQ:  // ^=
            self.pos = self.pos + 1
            return TokenKind.TK_CARET_EQ
        return TokenKind.TK_CARET
    if ch == CharCode.CH_AMPERSAND:
        self.pos = self.pos + 1
        if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.CH_EQ:  // &=
            self.pos = self.pos + 1
            return TokenKind.TK_AMP_EQ
        return TokenKind.TK_AMPERSAND

    // + compound operators
    if ch == CharCode.CH_PLUS:
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src.byte_at((self.pos) as i64)
            if c2 == CharCode.CH_PLUS:  // ++
                self.pos = self.pos + 1
                return TokenKind.TK_PLUS_PLUS
            if c2 == CharCode.CH_PERCENT:  // +% or +%=
                self.pos = self.pos + 1
                if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.CH_EQ:
                    self.pos = self.pos + 1
                    return TokenKind.TK_PLUS_WRAP_EQ
                return TokenKind.TK_PLUS_WRAP
            if c2 == CharCode.CH_EQ:  // +=
                self.pos = self.pos + 1
                return TokenKind.TK_PLUS_EQ
        return TokenKind.TK_PLUS

    // - compound operators
    if ch == CharCode.CH_MINUS:
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src.byte_at((self.pos) as i64)
            if c2 == CharCode.CH_GT:  // ->
                self.pos = self.pos + 1
                return TokenKind.TK_ARROW
            if c2 == CharCode.CH_PERCENT:  // -% or -%=
                self.pos = self.pos + 1
                if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.CH_EQ:
                    self.pos = self.pos + 1
                    return TokenKind.TK_MINUS_WRAP_EQ
                return TokenKind.TK_MINUS_WRAP
            if c2 == CharCode.CH_EQ:  // -=
                self.pos = self.pos + 1
                return TokenKind.TK_MINUS_EQ
        return TokenKind.TK_MINUS

    // * compound operators
    if ch == CharCode.CH_STAR:
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src.byte_at((self.pos) as i64)
            if c2 == CharCode.CH_PERCENT:  // *% or *%=
                self.pos = self.pos + 1
                if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.CH_EQ:
                    self.pos = self.pos + 1
                    return TokenKind.TK_STAR_WRAP_EQ
                return TokenKind.TK_STAR_WRAP
            if c2 == CharCode.CH_EQ:  // *=
                self.pos = self.pos + 1
                return TokenKind.TK_STAR_EQ
        return TokenKind.TK_STAR

    // % compound
    if ch == CharCode.CH_PERCENT:
        self.pos = self.pos + 1
        if self.pos < slen:
            if src.byte_at((self.pos) as i64) == CharCode.CH_EQ:  // %=
                self.pos = self.pos + 1
                return TokenKind.TK_PERCENT_EQ
        return TokenKind.TK_PERCENT

    // = compound
    if ch == CharCode.CH_EQ:
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src.byte_at((self.pos) as i64)
            if c2 == CharCode.CH_EQ:  // ==
                self.pos = self.pos + 1
                return TokenKind.TK_EQ_EQ
            if c2 == CharCode.CH_GT:  // =>
                self.pos = self.pos + 1
                return TokenKind.TK_FAT_ARROW
        return TokenKind.TK_EQ

    // ! compound
    if ch == CharCode.CH_BANG:
        self.pos = self.pos + 1
        if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.CH_EQ:  // !=
            self.pos = self.pos + 1
            return TokenKind.TK_BANG_EQ
        return TokenKind.TK_BANG

    // ? compound
    if ch == CharCode.CH_QUESTION:
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src.byte_at((self.pos) as i64)
            if c2 == CharCode.CH_DOT:  // ?.
                self.pos = self.pos + 1
                return TokenKind.TK_QUESTION_DOT
            if c2 == CharCode.CH_QUESTION:  // ??
                self.pos = self.pos + 1
                return TokenKind.TK_QUESTION_QUESTION
        return TokenKind.TK_QUESTION

    // < compound
    if ch == CharCode.CH_LT:
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src.byte_at((self.pos) as i64)
            if c2 == CharCode.CH_EQ:  // <=
                self.pos = self.pos + 1
                return TokenKind.TK_LT_EQ
            if c2 == CharCode.CH_LT:  // <<
                self.pos = self.pos + 1
                if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.CH_EQ:  // <<=
                    self.pos = self.pos + 1
                    return TokenKind.TK_LT_LT_EQ
                return TokenKind.TK_LT_LT
            if c2 == CharCode.CH_PIPE:  // <|
                self.pos = self.pos + 1
                return TokenKind.TK_LT_PIPE
        return TokenKind.TK_LT

    // > compound
    if ch == CharCode.CH_GT:
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src.byte_at((self.pos) as i64)
            if c2 == CharCode.CH_EQ:  // >=
                self.pos = self.pos + 1
                return TokenKind.TK_GT_EQ
            if c2 == CharCode.CH_GT:  // >>
                self.pos = self.pos + 1
                if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.CH_EQ:  // >>=
                    self.pos = self.pos + 1
                    return TokenKind.TK_GT_GT_EQ
                return TokenKind.TK_GT_GT
        return TokenKind.TK_GT

    // | compound
    if ch == CharCode.CH_PIPE:
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src.byte_at((self.pos) as i64)
            if c2 == CharCode.CH_GT:  // |>
                self.pos = self.pos + 1
                return TokenKind.TK_PIPE_GT
            if c2 == CharCode.CH_EQ:  // |=
                self.pos = self.pos + 1
                return TokenKind.TK_PIPE_EQ
        return TokenKind.TK_PIPE

    // / and //
    if ch == CharCode.CH_SLASH:
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src.byte_at((self.pos) as i64)
            if c2 == CharCode.CH_SLASH:  // // comment
                // Skip the rest of the line (comment is dropped)
                while self.pos < slen and src.byte_at((self.pos) as i64) != CharCode.CH_NEWLINE:
                    self.pos = self.pos + 1
                // Recurse to get the next real token
                return self.next_token()
            if c2 == CharCode.CH_EQ:  // /=
                self.pos = self.pos + 1
                return TokenKind.TK_SLASH_EQ
        return TokenKind.TK_SLASH

    // . compound
    if ch == CharCode.CH_DOT:
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src.byte_at((self.pos) as i64)
            if c2 == CharCode.CH_DOT:  // ..
                self.pos = self.pos + 1
                if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.CH_EQ:  // ..=
                    self.pos = self.pos + 1
                    return TokenKind.TK_DOT_DOT_EQ
                if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.CH_DOT:  // ...
                    self.pos = self.pos + 1
                    return TokenKind.TK_DOT_DOT_DOT
                return TokenKind.TK_DOT_DOT
            // .Uppercase = dot identifier
            if c2 >= CharCode.CH_A and c2 <= CharCode.CH_Z:
                return self.lex_dot_ident()
        return TokenKind.TK_DOT

    // String literal
    if ch == CharCode.CH_DQUOTE:
        return self.lex_string()

    // Number literal
    if ch >= CharCode.CH_0 and ch <= CharCode.CH_9:
        return self.lex_number()

    // Identifier or keyword
    if is_ident_start(ch):
        return self.lex_ident()

    // Character literal or label: 'x' / 'name
    if ch == CharCode.CH_SQUOTE:
        self.pos = self.pos + 1
        // Try char literal first: 'x', '\n', '\x41', ...
        if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.CH_BACKSLASH:
            if self.pos + 1 < slen:
                var p = self.pos + 1
                if src.byte_at((p) as i64) == CharCode.CH_x and p + 2 < slen:  // xNN
                    p = p + 2
                if p + 1 < slen and src.byte_at((p + 1) as i64) == CharCode.CH_SQUOTE:
                    self.pos = p + 2
                    return TokenKind.TK_CHAR_LIT
        if self.pos + 1 < slen and src.byte_at((self.pos + 1) as i64) == CharCode.CH_SQUOTE:
            // Single char: 'a'
            self.pos = self.pos + 2
            return TokenKind.TK_CHAR_LIT
        // Label: 'name
        if self.pos < slen and is_ident_start(src.byte_at((self.pos) as i64)):
            while self.pos < slen and is_ident_continue(src.byte_at((self.pos) as i64)):
                self.pos = self.pos + 1
            return TokenKind.TK_LABEL
        return TokenKind.TK_INVALID

    // Unknown character
    self.pos = self.pos + 1
    TokenKind.TK_INVALID


// --- Internal helpers ---

fn Lexer.skip_whitespace(self: Lexer):
    let src = self.source
    let slen = src.len() as i32
    while self.pos < slen:
        let ch = src.byte_at((self.pos) as i64)
        if not (ch == CharCode.CH_SPACE or ch == CharCode.CH_TAB or ch == CharCode.CH_CR):
            break
        self.pos = self.pos + 1

fn Lexer.lex_string(self: Lexer) -> i32:
    let src = self.source
    let slen = src.len() as i32
    self.pos = self.pos + 1  // skip opening "

    // Check for triple-quoted multi-line string: """..."""
    if self.pos + 1 < slen and src.byte_at((self.pos) as i64) == CharCode.CH_DQUOTE and src.byte_at((self.pos + 1) as i64) == CharCode.CH_DQUOTE:
        self.pos = self.pos + 2  // skip the two additional quotes
        // Skip optional leading newline after opening """
        if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.CH_NEWLINE:
            self.pos = self.pos + 1
        while self.pos + 2 < slen:
            if src.byte_at((self.pos) as i64) == CharCode.CH_DQUOTE and src.byte_at((self.pos + 1) as i64) == CharCode.CH_DQUOTE and src.byte_at((self.pos + 2) as i64) == CharCode.CH_DQUOTE:
                self.pos = self.pos + 3
                return TokenKind.TK_STRING_LIT
            if src.byte_at((self.pos) as i64) == CharCode.CH_BACKSLASH:
                self.pos = self.pos + 1
            self.pos = self.pos + 1
        // Unterminated multi-line string — return STRING_LIT for parser recovery.
        return TokenKind.TK_STRING_LIT

    // Track brace depth so that `"` inside interpolation holes `{...}` is not
    // treated as the end of the string.
    var brace_depth = 0
    while self.pos < slen:
        let ch = src.byte_at((self.pos) as i64)
        if ch == CharCode.CH_LBRACE and brace_depth == 0:
            // Don't count escaped braces. Count consecutive backslashes
            // preceding this '{' — an odd count means the brace is escaped.
            var bs = 0
            while bs < self.pos and src.byte_at((self.pos - 1 - bs) as i64) == CharCode.CH_BACKSLASH:
                bs = bs + 1
            if bs % 2 == 0:
                brace_depth = brace_depth + 1
                self.pos = self.pos + 1
                continue
        if ch == CharCode.CH_LBRACE and brace_depth > 0:
            brace_depth = brace_depth + 1
            self.pos = self.pos + 1
            continue
        if ch == CharCode.CH_RBRACE and brace_depth > 0:
            brace_depth = brace_depth - 1
            self.pos = self.pos + 1
            continue
        if ch == CharCode.CH_DQUOTE and brace_depth == 0:  // closing "
            self.pos = self.pos + 1
            return TokenKind.TK_STRING_LIT
        if ch == CharCode.CH_DQUOTE and brace_depth > 0:
            // Inside an interpolation hole: skip nested string literal.
            self.pos = self.pos + 1
            while self.pos < slen and src.byte_at((self.pos) as i64) != CharCode.CH_DQUOTE:
                if src.byte_at((self.pos) as i64) == CharCode.CH_BACKSLASH:
                    self.pos = self.pos + 1
                self.pos = self.pos + 1
            if self.pos < slen:
                self.pos = self.pos + 1
            continue
        if ch == CharCode.CH_BACKSLASH:  // backslash escape
            self.pos = self.pos + 1
        self.pos = self.pos + 1
    // Unterminated — return STRING_LIT for parser recovery.
    TokenKind.TK_STRING_LIT

fn Lexer.lex_number(self: Lexer) -> i32:
    let src = self.source
    let slen = src.len() as i32
    var is_float = false
    var scanned_prefixed = false

    // Check for 0x, 0b, 0o prefixes
    if src.byte_at((self.pos) as i64) == CharCode.CH_0 and self.pos + 1 < slen:
        let prefix = src.byte_at((self.pos + 1) as i64)
        if prefix == CharCode.CH_x or prefix == CharCode.CH_X:
            scanned_prefixed = true
            self.pos = self.pos + 2
            while self.pos < slen and (is_hex_digit(src.byte_at((self.pos) as i64)) or src.byte_at((self.pos) as i64) == CharCode.CH_UNDERSCORE):
                self.pos = self.pos + 1
        else if prefix == CharCode.CH_b or prefix == CharCode.CH_B:
            scanned_prefixed = true
            self.pos = self.pos + 2
            while self.pos < slen and (src.byte_at((self.pos) as i64) == CharCode.CH_0 or src.byte_at((self.pos) as i64) == CharCode.CH_1 or src.byte_at((self.pos) as i64) == CharCode.CH_UNDERSCORE):
                self.pos = self.pos + 1
        else if prefix == CharCode.CH_o or prefix == CharCode.CH_O:
            scanned_prefixed = true
            self.pos = self.pos + 2
            while self.pos < slen and ((src.byte_at((self.pos) as i64) >= CharCode.CH_0 and src.byte_at((self.pos) as i64) <= CharCode.CH_7) or src.byte_at((self.pos) as i64) == CharCode.CH_UNDERSCORE):
                self.pos = self.pos + 1

    if not scanned_prefixed:
        // Decimal digits
        while self.pos < slen and (lex_is_digit(src.byte_at((self.pos) as i64)) or src.byte_at((self.pos) as i64) == CharCode.CH_UNDERSCORE):
            self.pos = self.pos + 1

        // Check for decimal point (but not .. range)
        if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.CH_DOT:
            if self.pos + 1 < slen and src.byte_at((self.pos + 1) as i64) != CharCode.CH_DOT:
                is_float = true
                self.pos = self.pos + 1
                while self.pos < slen and (lex_is_digit(src.byte_at((self.pos) as i64)) or src.byte_at((self.pos) as i64) == CharCode.CH_UNDERSCORE):
                    self.pos = self.pos + 1

        // Check for exponent (e/E followed by optional +/- and digits)
        if self.pos < slen:
            let exp_ch = src.byte_at((self.pos) as i64)
            if exp_ch == CharCode.CH_e or exp_ch == CharCode.CH_E:
                is_float = true
                self.pos = self.pos + 1
                // Optional sign
                if self.pos < slen:
                    let sign_ch = src.byte_at((self.pos) as i64)
                    if sign_ch == CharCode.CH_PLUS or sign_ch == CharCode.CH_MINUS:
                        self.pos = self.pos + 1
                // Exponent digits
                while self.pos < slen and (lex_is_digit(src.byte_at((self.pos) as i64)) or src.byte_at((self.pos) as i64) == CharCode.CH_UNDERSCORE):
                    self.pos = self.pos + 1

    // Check for type suffix: 100i64, 3.14f32, 0xFFu32.
    var suffix_pos = self.pos
    if suffix_pos < slen and src.byte_at((suffix_pos) as i64) == CharCode.CH_UNDERSCORE:
        suffix_pos = suffix_pos + 1
    let suffix_len = numeric_suffix_len(src, suffix_pos, slen)
    if suffix_len > 0:
        let suffix_head = src.byte_at((suffix_pos) as i64)
        self.pos = suffix_pos + suffix_len
        if suffix_head == CharCode.CH_f:
            is_float = true

    if is_float:
        return TokenKind.TK_FLOAT_LIT
    TokenKind.TK_INT_LIT

fn numeric_suffix_len(src: str, pos: i32, slen: i32) -> i32:
    if pos >= slen:
        return 0
    let ch = src.byte_at((pos) as i64)
    if ch != CharCode.CH_i and ch != CharCode.CH_u and ch != CharCode.CH_f:
        return 0
    if suffix_accept(src, pos, slen, "usize", 5):
        return 5
    if suffix_accept(src, pos, slen, "isize", 5):
        return 5
    if suffix_accept(src, pos, slen, "u128", 4):
        return 4
    if suffix_accept(src, pos, slen, "i128", 4):
        return 4
    if suffix_accept(src, pos, slen, "u64", 3):
        return 3
    if suffix_accept(src, pos, slen, "i64", 3):
        return 3
    if suffix_accept(src, pos, slen, "u32", 3):
        return 3
    if suffix_accept(src, pos, slen, "i32", 3):
        return 3
    if suffix_accept(src, pos, slen, "u16", 3):
        return 3
    if suffix_accept(src, pos, slen, "i16", 3):
        return 3
    if suffix_accept(src, pos, slen, "f32", 3):
        return 3
    if suffix_accept(src, pos, slen, "f64", 3):
        return 3
    if suffix_accept(src, pos, slen, "u8", 2):
        return 2
    if suffix_accept(src, pos, slen, "i8", 2):
        return 2
    0

fn suffix_accept(src: str, pos: i32, slen: i32, suffix: str, suf_len: i32) -> bool:
    if pos + suf_len > slen:
        return false
    for i in 0..suf_len:
        if src.byte_at((pos + i) as i64) != suffix[i]:
            return false
    // Make sure it's not followed by more identifier chars.
    if pos + suf_len < slen and is_ident_continue(src.byte_at((pos + suf_len) as i64)):
        return false
    true

fn Lexer.lex_ident(self: Lexer) -> i32:
    let src = self.source
    let slen = src.len() as i32
    let start = self.token_start
    while self.pos < slen and is_ident_continue(src.byte_at((self.pos) as i64)):
        self.pos = self.pos + 1
    let text = src.slice(start as i64, self.pos as i64)

    // c"..." -> C-string literal
    if text == "c" and self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.CH_DQUOTE:
        self.pos = self.pos + 1  // skip opening "
        while self.pos < slen and src.byte_at((self.pos) as i64) != CharCode.CH_DQUOTE:
            if src.byte_at((self.pos) as i64) == CharCode.CH_BACKSLASH:
                self.pos = self.pos + 1
            self.pos = self.pos + 1
        if self.pos < slen:
            self.pos = self.pos + 1  // skip closing "
        return TokenKind.TK_C_STRING_LIT

    // r"..." / r#"..."# -> raw string literal (no escapes/interpolation)
    if text == "r":
        let raw_tok = self.lex_raw_string_prefixed()
        if raw_tok != -1:
            return raw_tok

    // f"..." -> interpolated string literal (f prefix + normal string lexing)
    if text == "f" and self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.CH_DQUOTE:
        self.pos = self.pos + 1  // skip opening "
        // Lex string body with brace-depth tracking (same as normal strings)
        var f_brace_depth = 0
        while self.pos < slen:
            let fch = src.byte_at((self.pos) as i64)
            if fch == CharCode.CH_LBRACE and f_brace_depth == 0:
                var fbs = 0
                while fbs < self.pos and src.byte_at((self.pos - 1 - fbs) as i64) == CharCode.CH_BACKSLASH:
                    fbs = fbs + 1
                if fbs % 2 == 0:
                    f_brace_depth = f_brace_depth + 1
                    self.pos = self.pos + 1
                    continue
            if fch == CharCode.CH_LBRACE and f_brace_depth > 0:
                f_brace_depth = f_brace_depth + 1
                self.pos = self.pos + 1
                continue
            if fch == CharCode.CH_RBRACE and f_brace_depth > 0:
                f_brace_depth = f_brace_depth - 1
                self.pos = self.pos + 1
                continue
            if fch == CharCode.CH_DQUOTE and f_brace_depth == 0:
                self.pos = self.pos + 1
                return TokenKind.TK_STRING_LIT
            if fch == CharCode.CH_BACKSLASH:
                self.pos = self.pos + 1
            self.pos = self.pos + 1
        return TokenKind.TK_STRING_LIT

    // b'...' -> byte literal (tokenized as char literal).
    if text == "b" and self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.CH_SQUOTE:
        let bt = self.lex_byte_char_prefixed()
        if bt != -1:
            return bt

    let kw = tag_from_keyword(text)
    if kw != -1:
        return kw
    TokenKind.TK_IDENT

fn Lexer.lex_dot_ident(self: Lexer) -> i32:
    let src = self.source
    let slen = src.len() as i32
    while self.pos < slen and is_ident_continue(src.byte_at((self.pos) as i64)):
        self.pos = self.pos + 1
    TokenKind.TK_DOT_IDENT

fn Lexer.lex_raw_string_prefixed(self: Lexer) -> i32:
    let src = self.source
    let slen = src.len() as i32
    var p = self.pos
    var hash_count = 0
    while p < slen and src.byte_at((p) as i64) == CharCode.CH_HASH:
        hash_count = hash_count + 1
        p = p + 1
    if p >= slen or src.byte_at((p) as i64) != CharCode.CH_DQUOTE:  // opening "
        return -1

    // Consume opening delimiter.
    self.pos = p + 1
    while self.pos < slen:
        if src.byte_at((self.pos) as i64) == CharCode.CH_DQUOTE:
            var ok = true
            for hi in 0..hash_count:
                if self.pos + 1 + hi >= slen or src.byte_at((self.pos + 1 + hi) as i64) != CharCode.CH_HASH:
                    ok = false
            if ok:
                self.pos = self.pos + 1 + hash_count
                return TokenKind.TK_STRING_LIT
        self.pos = self.pos + 1
    // Unterminated raw string: still emit string token for recovery.
    TokenKind.TK_STRING_LIT

fn Lexer.lex_byte_char_prefixed(self: Lexer) -> i32:
    let src = self.source
    let slen = src.len() as i32
    if self.pos >= slen or src.byte_at((self.pos) as i64) != CharCode.CH_SQUOTE:
        return -1
    self.pos = self.pos + 1  // skip opening '
    while self.pos < slen and src.byte_at((self.pos) as i64) != CharCode.CH_SQUOTE:
        if src.byte_at((self.pos) as i64) == CharCode.CH_BACKSLASH and self.pos + 1 < slen:
            self.pos = self.pos + 1
        self.pos = self.pos + 1
    if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.CH_SQUOTE:
        self.pos = self.pos + 1
    TokenKind.TK_CHAR_LIT


// --- Character classification ---

fn is_ident_start(ch: i32) -> bool:
    (ch >= CharCode.CH_A and ch <= CharCode.CH_Z) or (ch >= CharCode.CH_a and ch <= CharCode.CH_z) or ch == CharCode.CH_UNDERSCORE

fn is_ident_continue(ch: i32) -> bool:
    is_ident_start(ch) or (ch >= CharCode.CH_0 and ch <= CharCode.CH_9)

fn lex_is_digit(ch: i32) -> bool:
    ch >= CharCode.CH_0 and ch <= CharCode.CH_9

fn is_hex_digit(ch: i32) -> bool:
    (ch >= CharCode.CH_0 and ch <= CharCode.CH_9) or (ch >= CharCode.CH_A and ch <= CharCode.CH_F) or (ch >= CharCode.CH_a and ch <= CharCode.CH_f) or ch == CharCode.CH_UNDERSCORE

// Compute the 0-based column of a byte offset by scanning backward.
fn column_of(source: str, pos: i32) -> i32:
    var p = pos
    while p > 0:
        p = p - 1
        if source.byte_at((p) as i64) == CharCode.CH_NEWLINE:
            return pos - p - 1
    pos
