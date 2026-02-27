// Token — Token definitions for the With language.
//
// The lexer produces a flat list of tokens. Each token carries a tag
// and a span pointing back into the source text. Literal values and
// identifier text are recovered from the source via the span.

use Span

// All token kinds produced by the lexer.
// Represented as integer constants for fast comparison.

// -- Literals --
fn TK_INT_LIT() -> i32: 0
fn TK_FLOAT_LIT() -> i32: 1
fn TK_STRING_LIT() -> i32: 2
fn TK_C_STRING_LIT() -> i32: 3
fn TK_STRING_START() -> i32: 4
fn TK_STRING_END() -> i32: 5
fn TK_STRING_FRAGMENT() -> i32: 6
fn TK_CHAR_LIT() -> i32: 7
fn TK_TRUE() -> i32: 8
fn TK_FALSE() -> i32: 9

// -- Identifiers --
fn TK_IDENT() -> i32: 10
fn TK_DOT_IDENT() -> i32: 11
fn TK_LABEL() -> i32: 12

// -- Keywords --
fn TK_KW_FN() -> i32: 13
fn TK_KW_LET() -> i32: 14
fn TK_KW_VAR() -> i32: 15
fn TK_KW_IF() -> i32: 16
fn TK_KW_ELSE() -> i32: 17
fn TK_KW_THEN() -> i32: 18
fn TK_KW_MATCH() -> i32: 19
fn TK_KW_FOR() -> i32: 20
fn TK_KW_IN() -> i32: 21
fn TK_KW_WHILE() -> i32: 22
fn TK_KW_LOOP() -> i32: 23
fn TK_KW_RETURN() -> i32: 24
fn TK_KW_BREAK() -> i32: 25
fn TK_KW_CONTINUE() -> i32: 26
fn TK_KW_WITH() -> i32: 27
fn TK_KW_AS() -> i32: 28
fn TK_KW_MUT() -> i32: 29
fn TK_KW_TYPE() -> i32: 30
fn TK_KW_TRAIT() -> i32: 31
fn TK_KW_IMPL() -> i32: 32
fn TK_KW_EXTEND() -> i32: 33
fn TK_KW_DYN() -> i32: 34
fn TK_KW_USE() -> i32: 35
fn TK_KW_MODULE() -> i32: 36
fn TK_KW_PUB() -> i32: 37
fn TK_KW_ASYNC() -> i32: 38
fn TK_KW_AWAIT() -> i32: 39
fn TK_KW_SPAWN() -> i32: 40
fn TK_KW_UNSAFE() -> i32: 41
fn TK_KW_COMPTIME() -> i32: 42
fn TK_KW_GEN() -> i32: 43
fn TK_KW_YIELD() -> i32: 44
fn TK_KW_DEFER() -> i32: 45
fn TK_KW_ERROR() -> i32: 46
fn TK_KW_EXTERN() -> i32: 47
fn TK_KW_C_IMPORT() -> i32: 48
fn TK_KW_EPHEMERAL() -> i32: 49
fn TK_KW_SELECT() -> i32: 50
fn TK_KW_NOT() -> i32: 51
fn TK_KW_AND() -> i32: 52
fn TK_KW_OR() -> i32: 53

// -- Operators --
fn TK_PLUS() -> i32: 54
fn TK_MINUS() -> i32: 55
fn TK_STAR() -> i32: 56
fn TK_SLASH() -> i32: 57
fn TK_PERCENT() -> i32: 58
fn TK_PLUS_WRAP() -> i32: 59
fn TK_MINUS_WRAP() -> i32: 60
fn TK_STAR_WRAP() -> i32: 61
fn TK_EQ() -> i32: 62
fn TK_EQ_EQ() -> i32: 63
fn TK_BANG_EQ() -> i32: 64
fn TK_LT() -> i32: 65
fn TK_GT() -> i32: 66
fn TK_LT_EQ() -> i32: 67
fn TK_GT_EQ() -> i32: 68
fn TK_AMPERSAND() -> i32: 69
fn TK_PIPE() -> i32: 70
fn TK_CARET() -> i32: 71
fn TK_TILDE() -> i32: 72
fn TK_AT() -> i32: 73
fn TK_QUESTION() -> i32: 74
fn TK_QUESTION_DOT() -> i32: 75
fn TK_QUESTION_QUESTION() -> i32: 76
fn TK_ARROW() -> i32: 77
fn TK_FAT_ARROW() -> i32: 78
fn TK_DOT_DOT() -> i32: 79
fn TK_DOT_DOT_EQ() -> i32: 80
fn TK_DOT_DOT_DOT() -> i32: 81
fn TK_PIPE_GT() -> i32: 82
fn TK_LT_PIPE() -> i32: 83
fn TK_GT_GT() -> i32: 84
fn TK_LT_LT() -> i32: 85
fn TK_PLUS_PLUS() -> i32: 86
fn TK_PLUS_EQ() -> i32: 87
fn TK_MINUS_EQ() -> i32: 88
fn TK_STAR_EQ() -> i32: 89
fn TK_SLASH_EQ() -> i32: 90
fn TK_PERCENT_EQ() -> i32: 91

// -- Delimiters --
fn TK_L_PAREN() -> i32: 92
fn TK_R_PAREN() -> i32: 93
fn TK_L_BRACKET() -> i32: 94
fn TK_R_BRACKET() -> i32: 95
fn TK_L_BRACE() -> i32: 96
fn TK_R_BRACE() -> i32: 97

// -- Punctuation --
fn TK_COLON() -> i32: 98
fn TK_COMMA() -> i32: 99
fn TK_DOT() -> i32: 100
fn TK_SEMICOLON() -> i32: 101

// -- Structural --
fn TK_NEWLINE() -> i32: 102
fn TK_INDENT() -> i32: 103
fn TK_DEDENT() -> i32: 104

// -- Special --
fn TK_COMMENT() -> i32: 105
fn TK_EOF() -> i32: 106
fn TK_INVALID() -> i32: 107

// Token type: a tag plus the span in source text.
type Token = {
    tag: i32,
    start: i32,
    end: i32,
}

// Token list: parallel arrays of tags and spans for cache-friendly parsing.
type TokenList = {
    tags: Vec[i32],
    starts: Vec[i32],
    ends: Vec[i32],
}

fn TokenList.new() -> TokenList:
    TokenList {
        tags: Vec.new(),
        starts: Vec.new(),
        ends: Vec.new(),
    }

fn TokenList.append(self: TokenList, tag: i32, start: i32, end: i32) -> void:
    self.tags.push(tag)
    self.starts.push(start)
    self.ends.push(end)

fn TokenList.len(self: TokenList) -> i32:
    self.tags.len() as i32

fn TokenList.tag_at(self: TokenList, index: i32) -> i32:
    self.tags.get(index as i64)

fn TokenList.start_at(self: TokenList, index: i32) -> i32:
    self.starts.get(index as i64)

fn TokenList.end_at(self: TokenList, index: i32) -> i32:
    self.ends.get(index as i64)

// Keyword lookup: returns token tag if the string is a keyword, -1 otherwise.
fn keyword_lookup(s: str) -> i32:
    if s == "fn" then TK_KW_FN()
    else if s == "let" then TK_KW_LET()
    else if s == "var" then TK_KW_VAR()
    else if s == "if" then TK_KW_IF()
    else if s == "else" then TK_KW_ELSE()
    else if s == "then" then TK_KW_THEN()
    else if s == "match" then TK_KW_MATCH()
    else if s == "for" then TK_KW_FOR()
    else if s == "in" then TK_KW_IN()
    else if s == "while" then TK_KW_WHILE()
    else if s == "loop" then TK_KW_LOOP()
    else if s == "return" then TK_KW_RETURN()
    else if s == "break" then TK_KW_BREAK()
    else if s == "continue" then TK_KW_CONTINUE()
    else if s == "with" then TK_KW_WITH()
    else if s == "as" then TK_KW_AS()
    else if s == "mut" then TK_KW_MUT()
    else if s == "type" then TK_KW_TYPE()
    else if s == "trait" then TK_KW_TRAIT()
    else if s == "impl" then TK_KW_IMPL()
    else if s == "extend" then TK_KW_EXTEND()
    else if s == "dyn" then TK_KW_DYN()
    else if s == "use" then TK_KW_USE()
    else if s == "module" then TK_KW_MODULE()
    else if s == "pub" then TK_KW_PUB()
    else if s == "async" then TK_KW_ASYNC()
    else if s == "await" then TK_KW_AWAIT()
    else if s == "spawn" then TK_KW_SPAWN()
    else if s == "unsafe" then TK_KW_UNSAFE()
    else if s == "comptime" then TK_KW_COMPTIME()
    else if s == "gen" then TK_KW_GEN()
    else if s == "yield" then TK_KW_YIELD()
    else if s == "defer" then TK_KW_DEFER()
    else if s == "error" then TK_KW_ERROR()
    else if s == "extern" then TK_KW_EXTERN()
    else if s == "c_import" then TK_KW_C_IMPORT()
    else if s == "ephemeral" then TK_KW_EPHEMERAL()
    else if s == "select" then TK_KW_SELECT()
    else if s == "true" then TK_TRUE()
    else if s == "false" then TK_FALSE()
    else if s == "not" then TK_KW_NOT()
    else if s == "and" then TK_KW_AND()
    else if s == "or" then TK_KW_OR()
    else -1

// Human-readable name for a token tag (for diagnostics).
fn tag_name(tag: i32) -> str:
    if tag == TK_INT_LIT() then "integer literal"
    else if tag == TK_FLOAT_LIT() then "float literal"
    else if tag == TK_STRING_LIT() then "string literal"
    else if tag == TK_IDENT() then "identifier"
    else if tag == TK_KW_FN() then "'fn'"
    else if tag == TK_KW_LET() then "'let'"
    else if tag == TK_KW_VAR() then "'var'"
    else if tag == TK_KW_IF() then "'if'"
    else if tag == TK_KW_ELSE() then "'else'"
    else if tag == TK_KW_MATCH() then "'match'"
    else if tag == TK_KW_TYPE() then "'type'"
    else if tag == TK_KW_RETURN() then "'return'"
    else if tag == TK_PLUS() then "'+'"
    else if tag == TK_MINUS() then "'-'"
    else if tag == TK_STAR() then "'*'"
    else if tag == TK_SLASH() then "'/'"
    else if tag == TK_EQ() then "'='"
    else if tag == TK_EQ_EQ() then "'=='"
    else if tag == TK_L_PAREN() then "'('"
    else if tag == TK_R_PAREN() then "')'"
    else if tag == TK_L_BRACKET() then "'['"
    else if tag == TK_R_BRACKET() then "']'"
    else if tag == TK_L_BRACE() then "'{'"
    else if tag == TK_R_BRACE() then "'}'"
    else if tag == TK_COLON() then "':'"
    else if tag == TK_COMMA() then "','"
    else if tag == TK_DOT() then "'.'"
    else if tag == TK_ARROW() then "'->'"
    else if tag == TK_FAT_ARROW() then "'=>'"
    else if tag == TK_NEWLINE() then "newline"
    else if tag == TK_EOF() then "end of file"
    else if tag == TK_INVALID() then "invalid token"
    else "token"
