// Lexer — Tokenizer: source bytes to token stream.
//
// The lexer scans source text character-by-character and produces
// a flat list of tokens with source spans. Whitespace (except
// significant newlines) is consumed silently. Comments are skipped.

use Token

type Lexer = {
    source: str,
    pos: i32,
    file_id: i32,
}

fn Lexer.new(source: str, file_id: i32) -> Lexer:
    Lexer { source: source, pos: 0, file_id: file_id }

// Tokenize the entire source, returning a token list ending with EOF.
fn Lexer.tokenize(self: *mut Lexer) -> TokenList:
    var tokens = TokenList.new()
    loop:
        let tag = Lexer.next_token(self, &tokens)
        if tag == TK_EOF():
            break
    tokens

// Produce the next token, appending it to the list. Returns the tag.
fn Lexer.next_token(self: *mut Lexer, tokens: *mut TokenList) -> i32:
    Lexer.skip_whitespace(self)

    let src = self.source
    let slen = src.len() as i32

    if self.pos >= slen:
        TokenList.append(tokens, TK_EOF(), self.pos, self.pos)
        return TK_EOF()

    let start = self.pos
    let ch = src[self.pos]

    // Newline
    if ch == 10:
        self.pos = self.pos + 1
        TokenList.append(tokens, TK_NEWLINE(), start, self.pos)
        return TK_NEWLINE()

    // Single-character delimiters and punctuation
    if ch == 40:  // (
        self.pos = self.pos + 1
        TokenList.append(tokens, TK_L_PAREN(), start, self.pos)
        return TK_L_PAREN()
    if ch == 41:  // )
        self.pos = self.pos + 1
        TokenList.append(tokens, TK_R_PAREN(), start, self.pos)
        return TK_R_PAREN()
    if ch == 91:  // [
        self.pos = self.pos + 1
        TokenList.append(tokens, TK_L_BRACKET(), start, self.pos)
        return TK_L_BRACKET()
    if ch == 93:  // ]
        self.pos = self.pos + 1
        TokenList.append(tokens, TK_R_BRACKET(), start, self.pos)
        return TK_R_BRACKET()
    if ch == 123:  // {
        self.pos = self.pos + 1
        TokenList.append(tokens, TK_L_BRACE(), start, self.pos)
        return TK_L_BRACE()
    if ch == 125:  // }
        self.pos = self.pos + 1
        TokenList.append(tokens, TK_R_BRACE(), start, self.pos)
        return TK_R_BRACE()
    if ch == 44:  // ,
        self.pos = self.pos + 1
        TokenList.append(tokens, TK_COMMA(), start, self.pos)
        return TK_COMMA()
    if ch == 59:  // ;
        self.pos = self.pos + 1
        TokenList.append(tokens, TK_SEMICOLON(), start, self.pos)
        return TK_SEMICOLON()
    if ch == 58:  // :
        self.pos = self.pos + 1
        TokenList.append(tokens, TK_COLON(), start, self.pos)
        return TK_COLON()
    if ch == 126:  // ~
        self.pos = self.pos + 1
        TokenList.append(tokens, TK_TILDE(), start, self.pos)
        return TK_TILDE()
    if ch == 64:  // @
        self.pos = self.pos + 1
        TokenList.append(tokens, TK_AT(), start, self.pos)
        return TK_AT()
    if ch == 94:  // ^
        self.pos = self.pos + 1
        TokenList.append(tokens, TK_CARET(), start, self.pos)
        return TK_CARET()
    if ch == 38:  // &
        self.pos = self.pos + 1
        TokenList.append(tokens, TK_AMPERSAND(), start, self.pos)
        return TK_AMPERSAND()

    // + compound operators
    if ch == 43:  // +
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src[self.pos]
            if c2 == 43:  // ++
                self.pos = self.pos + 1
                TokenList.append(tokens, TK_PLUS_PLUS(), start, self.pos)
                return TK_PLUS_PLUS()
            if c2 == 37:  // +%
                self.pos = self.pos + 1
                TokenList.append(tokens, TK_PLUS_WRAP(), start, self.pos)
                return TK_PLUS_WRAP()
            if c2 == 61:  // +=
                self.pos = self.pos + 1
                TokenList.append(tokens, TK_PLUS_EQ(), start, self.pos)
                return TK_PLUS_EQ()
        TokenList.append(tokens, TK_PLUS(), start, self.pos)
        return TK_PLUS()

    // - compound operators
    if ch == 45:  // -
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src[self.pos]
            if c2 == 62:  // ->
                self.pos = self.pos + 1
                TokenList.append(tokens, TK_ARROW(), start, self.pos)
                return TK_ARROW()
            if c2 == 37:  // -%
                self.pos = self.pos + 1
                TokenList.append(tokens, TK_MINUS_WRAP(), start, self.pos)
                return TK_MINUS_WRAP()
            if c2 == 61:  // -=
                self.pos = self.pos + 1
                TokenList.append(tokens, TK_MINUS_EQ(), start, self.pos)
                return TK_MINUS_EQ()
        TokenList.append(tokens, TK_MINUS(), start, self.pos)
        return TK_MINUS()

    // * compound operators
    if ch == 42:  // *
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src[self.pos]
            if c2 == 37:  // *%
                self.pos = self.pos + 1
                TokenList.append(tokens, TK_STAR_WRAP(), start, self.pos)
                return TK_STAR_WRAP()
            if c2 == 61:  // *=
                self.pos = self.pos + 1
                TokenList.append(tokens, TK_STAR_EQ(), start, self.pos)
                return TK_STAR_EQ()
        TokenList.append(tokens, TK_STAR(), start, self.pos)
        return TK_STAR()

    // % compound
    if ch == 37:  // %
        self.pos = self.pos + 1
        if self.pos < slen:
            if src[self.pos] == 61:  // %=
                self.pos = self.pos + 1
                TokenList.append(tokens, TK_PERCENT_EQ(), start, self.pos)
                return TK_PERCENT_EQ()
        TokenList.append(tokens, TK_PERCENT(), start, self.pos)
        return TK_PERCENT()

    // = compound
    if ch == 61:  // =
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src[self.pos]
            if c2 == 61:  // ==
                self.pos = self.pos + 1
                TokenList.append(tokens, TK_EQ_EQ(), start, self.pos)
                return TK_EQ_EQ()
            if c2 == 62:  // =>
                self.pos = self.pos + 1
                TokenList.append(tokens, TK_FAT_ARROW(), start, self.pos)
                return TK_FAT_ARROW()
        TokenList.append(tokens, TK_EQ(), start, self.pos)
        return TK_EQ()

    // ! compound
    if ch == 33:  // !
        self.pos = self.pos + 1
        if self.pos < slen and src[self.pos] == 61:  // !=
            self.pos = self.pos + 1
            TokenList.append(tokens, TK_BANG_EQ(), start, self.pos)
            return TK_BANG_EQ()
        TokenList.append(tokens, TK_INVALID(), start, self.pos)
        return TK_INVALID()

    // ? compound
    if ch == 63:  // ?
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src[self.pos]
            if c2 == 46:  // ?.
                self.pos = self.pos + 1
                TokenList.append(tokens, TK_QUESTION_DOT(), start, self.pos)
                return TK_QUESTION_DOT()
            if c2 == 63:  // ??
                self.pos = self.pos + 1
                TokenList.append(tokens, TK_QUESTION_QUESTION(), start, self.pos)
                return TK_QUESTION_QUESTION()
        TokenList.append(tokens, TK_QUESTION(), start, self.pos)
        return TK_QUESTION()

    // < compound
    if ch == 60:  // <
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src[self.pos]
            if c2 == 61:  // <=
                self.pos = self.pos + 1
                TokenList.append(tokens, TK_LT_EQ(), start, self.pos)
                return TK_LT_EQ()
            if c2 == 60:  // <<
                self.pos = self.pos + 1
                TokenList.append(tokens, TK_LT_LT(), start, self.pos)
                return TK_LT_LT()
            if c2 == 124:  // <|
                self.pos = self.pos + 1
                TokenList.append(tokens, TK_LT_PIPE(), start, self.pos)
                return TK_LT_PIPE()
        TokenList.append(tokens, TK_LT(), start, self.pos)
        return TK_LT()

    // > compound
    if ch == 62:  // >
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src[self.pos]
            if c2 == 61:  // >=
                self.pos = self.pos + 1
                TokenList.append(tokens, TK_GT_EQ(), start, self.pos)
                return TK_GT_EQ()
            if c2 == 62:  // >>
                self.pos = self.pos + 1
                TokenList.append(tokens, TK_GT_GT(), start, self.pos)
                return TK_GT_GT()
        TokenList.append(tokens, TK_GT(), start, self.pos)
        return TK_GT()

    // | compound
    if ch == 124:  // |
        self.pos = self.pos + 1
        if self.pos < slen and src[self.pos] == 62:  // |>
            self.pos = self.pos + 1
            TokenList.append(tokens, TK_PIPE_GT(), start, self.pos)
            return TK_PIPE_GT()
        TokenList.append(tokens, TK_PIPE(), start, self.pos)
        return TK_PIPE()

    // / and //
    if ch == 47:  // /
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src[self.pos]
            if c2 == 47:  // // comment
                // Skip the rest of the line (comment is dropped)
                while self.pos < slen and src[self.pos] != 10:
                    self.pos = self.pos + 1
                // Recurse to get the next real token
                return Lexer.next_token(self, tokens)
            if c2 == 61:  // /=
                self.pos = self.pos + 1
                TokenList.append(tokens, TK_SLASH_EQ(), start, self.pos)
                return TK_SLASH_EQ()
        TokenList.append(tokens, TK_SLASH(), start, self.pos)
        return TK_SLASH()

    // . compound
    if ch == 46:  // .
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src[self.pos]
            if c2 == 46:  // ..
                self.pos = self.pos + 1
                if self.pos < slen and src[self.pos] == 61:  // ..=
                    self.pos = self.pos + 1
                    TokenList.append(tokens, TK_DOT_DOT_EQ(), start, self.pos)
                    return TK_DOT_DOT_EQ()
                if self.pos < slen and src[self.pos] == 46:  // ...
                    self.pos = self.pos + 1
                    TokenList.append(tokens, TK_DOT_DOT_DOT(), start, self.pos)
                    return TK_DOT_DOT_DOT()
                TokenList.append(tokens, TK_DOT_DOT(), start, self.pos)
                return TK_DOT_DOT()
            // .Uppercase = dot identifier
            if c2 >= 65 and c2 <= 90:
                return Lexer.lex_dot_ident(self, tokens, start)
        TokenList.append(tokens, TK_DOT(), start, self.pos)
        return TK_DOT()

    // String literal
    if ch == 34:  // "
        return Lexer.lex_string(self, tokens, start)

    // Number literal
    if ch >= 48 and ch <= 57:  // 0-9
        return Lexer.lex_number(self, tokens, start)

    // Identifier or keyword
    if is_ident_start(ch):
        return Lexer.lex_ident(self, tokens, start)

    // Label: 'name
    if ch == 39:  // '
        self.pos = self.pos + 1
        if self.pos < slen and is_ident_start(src[self.pos]):
            while self.pos < slen and is_ident_continue(src[self.pos]):
                self.pos = self.pos + 1
            TokenList.append(tokens, TK_LABEL(), start, self.pos)
            return TK_LABEL()
        TokenList.append(tokens, TK_INVALID(), start, self.pos)
        return TK_INVALID()

    // Unknown character
    self.pos = self.pos + 1
    TokenList.append(tokens, TK_INVALID(), start, self.pos)
    return TK_INVALID()


// --- Internal helpers ---

fn Lexer.skip_whitespace(self: *mut Lexer) -> void:
    let src = self.source
    let slen = src.len() as i32
    while self.pos < slen:
        let ch = src[self.pos]
        if not (ch == 32 or ch == 9 or ch == 13):
            break
        self.pos = self.pos + 1

fn Lexer.lex_string(self: *mut Lexer, tokens: *mut TokenList, start: i32) -> i32:
    let src = self.source
    let slen = src.len() as i32
    self.pos = self.pos + 1  // skip opening "
    while self.pos < slen:
        let ch = src[self.pos]
        if ch == 34:  // closing "
            self.pos = self.pos + 1
            TokenList.append(tokens, TK_STRING_LIT(), start, self.pos)
            return TK_STRING_LIT()
        if ch == 92:  // backslash escape
            self.pos = self.pos + 1
        self.pos = self.pos + 1
    // Unterminated
    TokenList.append(tokens, TK_STRING_LIT(), start, self.pos)
    return TK_STRING_LIT()

fn Lexer.lex_number(self: *mut Lexer, tokens: *mut TokenList, start: i32) -> i32:
    let src = self.source
    let slen = src.len() as i32
    var is_float = false

    // Check for 0x, 0b, 0o prefixes
    if src[self.pos] == 48 and self.pos + 1 < slen:
        let prefix = src[self.pos + 1]
        if prefix == 120 or prefix == 88:  // x, X
            self.pos = self.pos + 2
            while self.pos < slen and is_hex_digit(src[self.pos]):
                self.pos = self.pos + 1
            TokenList.append(tokens, TK_INT_LIT(), start, self.pos)
            return TK_INT_LIT()
        if prefix == 98 or prefix == 66:  // b, B
            self.pos = self.pos + 2
            while self.pos < slen and (src[self.pos] == 48 or src[self.pos] == 49 or src[self.pos] == 95):
                self.pos = self.pos + 1
            TokenList.append(tokens, TK_INT_LIT(), start, self.pos)
            return TK_INT_LIT()
        if prefix == 111 or prefix == 79:  // o, O
            self.pos = self.pos + 2
            while self.pos < slen and ((src[self.pos] >= 48 and src[self.pos] <= 55) or src[self.pos] == 95):
                self.pos = self.pos + 1
            TokenList.append(tokens, TK_INT_LIT(), start, self.pos)
            return TK_INT_LIT()

    // Decimal digits
    while self.pos < slen and (is_digit(src[self.pos]) or src[self.pos] == 95):
        self.pos = self.pos + 1

    // Check for decimal point (but not .. range)
    if self.pos < slen and src[self.pos] == 46:
        if self.pos + 1 < slen and src[self.pos + 1] != 46:
            is_float = true
            self.pos = self.pos + 1
            while self.pos < slen and (is_digit(src[self.pos]) or src[self.pos] == 95):
                self.pos = self.pos + 1

    if is_float:
        TokenList.append(tokens, TK_FLOAT_LIT(), start, self.pos)
        return TK_FLOAT_LIT()
    TokenList.append(tokens, TK_INT_LIT(), start, self.pos)
    return TK_INT_LIT()

fn Lexer.lex_ident(self: *mut Lexer, tokens: *mut TokenList, start: i32) -> i32:
    let src = self.source
    let slen = src.len() as i32
    while self.pos < slen and is_ident_continue(src[self.pos]):
        self.pos = self.pos + 1
    let text = src.slice(start as i64, self.pos as i64)

    // c"..." → C-string literal
    if text == "c" and self.pos < slen and src[self.pos] == 34:
        self.pos = self.pos + 1  // skip opening "
        while self.pos < slen and src[self.pos] != 34:
            if src[self.pos] == 92:
                self.pos = self.pos + 1
            self.pos = self.pos + 1
        if self.pos < slen:
            self.pos = self.pos + 1  // skip closing "
        TokenList.append(tokens, TK_C_STRING_LIT(), start, self.pos)
        return TK_C_STRING_LIT()

    let kw = keyword_lookup(text)
    if kw != -1:
        TokenList.append(tokens, kw, start, self.pos)
        return kw
    TokenList.append(tokens, TK_IDENT(), start, self.pos)
    return TK_IDENT()

fn Lexer.lex_dot_ident(self: *mut Lexer, tokens: *mut TokenList, start: i32) -> i32:
    let src = self.source
    let slen = src.len() as i32
    while self.pos < slen and is_ident_continue(src[self.pos]):
        self.pos = self.pos + 1
    TokenList.append(tokens, TK_DOT_IDENT(), start, self.pos)
    return TK_DOT_IDENT()


// --- Character classification ---

fn is_ident_start(ch: i32) -> bool:
    (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122) or ch == 95

fn is_ident_continue(ch: i32) -> bool:
    is_ident_start(ch) or (ch >= 48 and ch <= 57)

fn is_digit(ch: i32) -> bool:
    ch >= 48 and ch <= 57

fn is_hex_digit(ch: i32) -> bool:
    (ch >= 48 and ch <= 57) or (ch >= 65 and ch <= 70) or (ch >= 97 and ch <= 102) or ch == 95
