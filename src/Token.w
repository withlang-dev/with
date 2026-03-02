// Token — Token definitions for the With language.
//
// The lexer produces a flat list of tokens. Each token carries a tag
// and a span pointing back into the source text. Literal values and
// identifier text are recovered from the source via the span.

use Span

// All token kinds produced by the lexer.
// Represented as integer constants for fast comparison.

// -- Literals --
fn TK_INT_LIT -> i32: 0
fn TK_FLOAT_LIT -> i32: 1
fn TK_STRING_LIT -> i32: 2
fn TK_C_STRING_LIT -> i32: 3
fn TK_STRING_START -> i32: 4
fn TK_STRING_END -> i32: 5
fn TK_STRING_FRAGMENT -> i32: 6
fn TK_CHAR_LIT -> i32: 7
fn TK_TRUE -> i32: 8
fn TK_FALSE -> i32: 9

// -- Identifiers --
fn TK_IDENT -> i32: 10
fn TK_DOT_IDENT -> i32: 11
fn TK_LABEL -> i32: 12

// -- Keywords --
fn TK_KW_FN -> i32: 13
fn TK_KW_LET -> i32: 14
fn TK_KW_VAR -> i32: 15
fn TK_KW_IF -> i32: 16
fn TK_KW_ELSE -> i32: 17
fn TK_KW_THEN -> i32: 18
fn TK_KW_MATCH -> i32: 19
fn TK_KW_FOR -> i32: 20
fn TK_KW_IN -> i32: 21
fn TK_KW_WHILE -> i32: 22
fn TK_KW_LOOP -> i32: 23
fn TK_KW_RETURN -> i32: 24
fn TK_KW_BREAK -> i32: 25
fn TK_KW_CONTINUE -> i32: 26
fn TK_KW_WITH -> i32: 27
fn TK_KW_AS -> i32: 28
fn TK_KW_MUT -> i32: 29
fn TK_KW_TYPE -> i32: 30
fn TK_KW_TRAIT -> i32: 31
fn TK_KW_IMPL -> i32: 32
fn TK_KW_EXTEND -> i32: 33
fn TK_KW_DYN -> i32: 34
fn TK_KW_USE -> i32: 35
fn TK_KW_MODULE -> i32: 36
fn TK_KW_PUB -> i32: 37
fn TK_KW_ASYNC -> i32: 38
fn TK_KW_AWAIT -> i32: 39
fn TK_KW_SPAWN -> i32: 40
fn TK_KW_UNSAFE -> i32: 41
fn TK_KW_COMPTIME -> i32: 42
fn TK_KW_GEN -> i32: 43
fn TK_KW_YIELD -> i32: 44
fn TK_KW_DEFER -> i32: 45
fn TK_KW_ERROR -> i32: 46
fn TK_KW_EXTERN -> i32: 47
fn TK_KW_C_IMPORT -> i32: 48
fn TK_KW_EPHEMERAL -> i32: 49
fn TK_KW_SELECT -> i32: 50
fn TK_KW_NOT -> i32: 51
fn TK_KW_AND -> i32: 52
fn TK_KW_OR -> i32: 53

// -- Operators --
fn TK_PLUS -> i32: 54
fn TK_MINUS -> i32: 55
fn TK_STAR -> i32: 56
fn TK_SLASH -> i32: 57
fn TK_PERCENT -> i32: 58
fn TK_PLUS_WRAP -> i32: 59
fn TK_MINUS_WRAP -> i32: 60
fn TK_STAR_WRAP -> i32: 61
fn TK_EQ -> i32: 62
fn TK_EQ_EQ -> i32: 63
fn TK_BANG -> i32: 64
fn TK_BANG_EQ -> i32: 65
fn TK_LT -> i32: 66
fn TK_GT -> i32: 67
fn TK_LT_EQ -> i32: 68
fn TK_GT_EQ -> i32: 69
fn TK_AMPERSAND -> i32: 70
fn TK_PIPE -> i32: 71
fn TK_CARET -> i32: 72
fn TK_TILDE -> i32: 73
fn TK_AT -> i32: 74
fn TK_QUESTION -> i32: 75
fn TK_QUESTION_DOT -> i32: 76
fn TK_QUESTION_QUESTION -> i32: 77
fn TK_ARROW -> i32: 78
fn TK_FAT_ARROW -> i32: 79
fn TK_DOT_DOT -> i32: 80
fn TK_DOT_DOT_EQ -> i32: 81
fn TK_DOT_DOT_DOT -> i32: 82
fn TK_PIPE_GT -> i32: 83
fn TK_LT_PIPE -> i32: 84
fn TK_GT_GT -> i32: 85
fn TK_LT_LT -> i32: 86
fn TK_PLUS_PLUS -> i32: 87
fn TK_PLUS_EQ -> i32: 88
fn TK_MINUS_EQ -> i32: 89
fn TK_STAR_EQ -> i32: 90
fn TK_SLASH_EQ -> i32: 91
fn TK_PERCENT_EQ -> i32: 92

// -- Delimiters --
fn TK_L_PAREN -> i32: 93
fn TK_R_PAREN -> i32: 94
fn TK_L_BRACKET -> i32: 95
fn TK_R_BRACKET -> i32: 96
fn TK_L_BRACE -> i32: 97
fn TK_R_BRACE -> i32: 98

// -- Punctuation --
fn TK_COLON -> i32: 99
fn TK_COMMA -> i32: 100
fn TK_DOT -> i32: 101
fn TK_SEMICOLON -> i32: 102

// -- Structural --
fn TK_NEWLINE -> i32: 103
fn TK_INDENT -> i32: 104
fn TK_DEDENT -> i32: 105

// -- Special --
fn TK_COMMENT -> i32: 106
fn TK_EOF -> i32: 107
fn TK_INVALID -> i32: 108

// Lookup table: keyword string -> tag. Returns -1 if not a keyword.
fn tag_from_keyword(s: str) -> i32:
    if s == "fn": return TK_KW_FN()
    if s == "let": return TK_KW_LET()
    if s == "var": return TK_KW_VAR()
    if s == "if": return TK_KW_IF()
    if s == "else": return TK_KW_ELSE()
    if s == "then": return TK_KW_THEN()
    if s == "match": return TK_KW_MATCH()
    if s == "for": return TK_KW_FOR()
    if s == "in": return TK_KW_IN()
    if s == "while": return TK_KW_WHILE()
    if s == "loop": return TK_KW_LOOP()
    if s == "return": return TK_KW_RETURN()
    if s == "break": return TK_KW_BREAK()
    if s == "continue": return TK_KW_CONTINUE()
    if s == "with": return TK_KW_WITH()
    if s == "as": return TK_KW_AS()
    if s == "mut": return TK_KW_MUT()
    if s == "type": return TK_KW_TYPE()
    if s == "trait": return TK_KW_TRAIT()
    if s == "impl": return TK_KW_IMPL()
    if s == "extend": return TK_KW_EXTEND()
    if s == "dyn": return TK_KW_DYN()
    if s == "use": return TK_KW_USE()
    if s == "module": return TK_KW_MODULE()
    if s == "pub": return TK_KW_PUB()
    if s == "async": return TK_KW_ASYNC()
    if s == "await": return TK_KW_AWAIT()
    if s == "spawn": return TK_KW_SPAWN()
    if s == "unsafe": return TK_KW_UNSAFE()
    if s == "comptime": return TK_KW_COMPTIME()
    if s == "gen": return TK_KW_GEN()
    if s == "yield": return TK_KW_YIELD()
    if s == "defer": return TK_KW_DEFER()
    if s == "error": return TK_KW_ERROR()
    if s == "extern": return TK_KW_EXTERN()
    if s == "c_import": return TK_KW_C_IMPORT()
    if s == "ephemeral": return TK_KW_EPHEMERAL()
    if s == "select": return TK_KW_SELECT()
    if s == "true": return TK_TRUE()
    if s == "false": return TK_FALSE()
    if s == "not": return TK_KW_NOT()
    if s == "and": return TK_KW_AND()
    if s == "or": return TK_KW_OR()
    -1

// Returns a human-readable name for a token tag (for diagnostics).
fn tag_name(tag: i32) -> str:
    if tag == TK_INT_LIT(): return "integer literal"
    if tag == TK_FLOAT_LIT(): return "float literal"
    if tag == TK_STRING_LIT(): return "string literal"
    if tag == TK_C_STRING_LIT(): return "c-string literal"
    if tag == TK_STRING_START(): return "string start"
    if tag == TK_STRING_END(): return "string end"
    if tag == TK_STRING_FRAGMENT(): return "string fragment"
    if tag == TK_CHAR_LIT(): return "character literal"
    if tag == TK_TRUE(): return "'true'"
    if tag == TK_FALSE(): return "'false'"
    if tag == TK_IDENT(): return "identifier"
    if tag == TK_DOT_IDENT(): return "dot-identifier"
    if tag == TK_LABEL(): return "label"
    if tag == TK_KW_FN(): return "'fn'"
    if tag == TK_KW_LET(): return "'let'"
    if tag == TK_KW_VAR(): return "'var'"
    if tag == TK_KW_IF(): return "'if'"
    if tag == TK_KW_ELSE(): return "'else'"
    if tag == TK_KW_THEN(): return "'then'"
    if tag == TK_KW_MATCH(): return "'match'"
    if tag == TK_KW_FOR(): return "'for'"
    if tag == TK_KW_IN(): return "'in'"
    if tag == TK_KW_WHILE(): return "'while'"
    if tag == TK_KW_LOOP(): return "'loop'"
    if tag == TK_KW_RETURN(): return "'return'"
    if tag == TK_KW_BREAK(): return "'break'"
    if tag == TK_KW_CONTINUE(): return "'continue'"
    if tag == TK_KW_WITH(): return "'with'"
    if tag == TK_KW_AS(): return "'as'"
    if tag == TK_KW_MUT(): return "'mut'"
    if tag == TK_KW_TYPE(): return "'type'"
    if tag == TK_KW_TRAIT(): return "'trait'"
    if tag == TK_KW_IMPL(): return "'impl'"
    if tag == TK_KW_EXTEND(): return "'extend'"
    if tag == TK_KW_DYN(): return "'dyn'"
    if tag == TK_KW_USE(): return "'use'"
    if tag == TK_KW_MODULE(): return "'module'"
    if tag == TK_KW_PUB(): return "'pub'"
    if tag == TK_KW_ASYNC(): return "'async'"
    if tag == TK_KW_AWAIT(): return "'await'"
    if tag == TK_KW_SPAWN(): return "'spawn'"
    if tag == TK_KW_UNSAFE(): return "'unsafe'"
    if tag == TK_KW_COMPTIME(): return "'comptime'"
    if tag == TK_KW_GEN(): return "'gen'"
    if tag == TK_KW_YIELD(): return "'yield'"
    if tag == TK_KW_DEFER(): return "'defer'"
    if tag == TK_KW_ERROR(): return "'error'"
    if tag == TK_KW_EXTERN(): return "'extern'"
    if tag == TK_KW_C_IMPORT(): return "'c_import'"
    if tag == TK_KW_EPHEMERAL(): return "'ephemeral'"
    if tag == TK_KW_SELECT(): return "'select'"
    if tag == TK_KW_NOT(): return "'not'"
    if tag == TK_KW_AND(): return "'and'"
    if tag == TK_KW_OR(): return "'or'"
    if tag == TK_PLUS(): return "'+'"
    if tag == TK_MINUS(): return "'-'"
    if tag == TK_STAR(): return "'*'"
    if tag == TK_SLASH(): return "'/'"
    if tag == TK_PERCENT(): return "'%'"
    if tag == TK_PLUS_WRAP(): return "'+%'"
    if tag == TK_MINUS_WRAP(): return "'-%'"
    if tag == TK_STAR_WRAP(): return "'*%'"
    if tag == TK_EQ(): return "'='"
    if tag == TK_EQ_EQ(): return "'=='"
    if tag == TK_BANG(): return "'!'"
    if tag == TK_BANG_EQ(): return "'!='"
    if tag == TK_LT(): return "'<'"
    if tag == TK_GT(): return "'>'"
    if tag == TK_LT_EQ(): return "'<='"
    if tag == TK_GT_EQ(): return "'>='"
    if tag == TK_AMPERSAND(): return "'&'"
    if tag == TK_PIPE(): return "'|'"
    if tag == TK_CARET(): return "'^'"
    if tag == TK_TILDE(): return "'~'"
    if tag == TK_AT(): return "'@'"
    if tag == TK_QUESTION(): return "'?'"
    if tag == TK_QUESTION_DOT(): return "'?.'"
    if tag == TK_QUESTION_QUESTION(): return "'??'"
    if tag == TK_ARROW(): return "'->'"
    if tag == TK_FAT_ARROW(): return "'=>'"
    if tag == TK_DOT_DOT(): return "'..'"
    if tag == TK_DOT_DOT_EQ(): return "'..='"
    if tag == TK_DOT_DOT_DOT(): return "'...'"
    if tag == TK_PIPE_GT(): return "'|>'"
    if tag == TK_LT_PIPE(): return "'<|'"
    if tag == TK_GT_GT(): return "'>>'"
    if tag == TK_LT_LT(): return "'<<'"
    if tag == TK_PLUS_PLUS(): return "'++'"
    if tag == TK_PLUS_EQ(): return "'+='"
    if tag == TK_MINUS_EQ(): return "'-='"
    if tag == TK_STAR_EQ(): return "'*='"
    if tag == TK_SLASH_EQ(): return "'/='"
    if tag == TK_PERCENT_EQ(): return "'%='"
    if tag == TK_L_PAREN(): return "'('"
    if tag == TK_R_PAREN(): return "')'"
    if tag == TK_L_BRACKET(): return "'['"
    if tag == TK_R_BRACKET(): return "']'"
    if tag == TK_L_BRACE(): return "left brace"
    if tag == TK_R_BRACE(): return "right brace"
    if tag == TK_COLON(): return "':'"
    if tag == TK_COMMA(): return "','"
    if tag == TK_DOT(): return "'.'"
    if tag == TK_SEMICOLON(): return "';'"
    if tag == TK_NEWLINE(): return "newline"
    if tag == TK_INDENT(): return "indent"
    if tag == TK_DEDENT(): return "dedent"
    if tag == TK_COMMENT(): return "comment"
    if tag == TK_EOF(): return "end of file"
    if tag == TK_INVALID(): return "invalid token"
    "unknown"

// A growable list of tokens stored as parallel arrays for
// cache-friendly iteration over tags alone.
type TokenList = {
    tags: Vec[i32],
    starts: Vec[i32],
    ends: Vec[i32],
}

fn TokenList.new -> TokenList:
    TokenList {
        tags: Vec.new(),
        starts: Vec.new(),
        ends: Vec.new(),
    }

fn TokenList.deinit(self: TokenList):
    return

fn TokenList.append(self: TokenList, tag: i32, start: i32, end: i32):
    self.tags.push(tag)
    self.starts.push(start)
    self.ends.push(end)

fn TokenList.len(self: TokenList) -> i32:
    self.tags.len() as i32

fn TokenList.get_tag(self: TokenList, index: i32) -> i32:
    self.tags.get(index as i64)

fn TokenList.get_start(self: TokenList, index: i32) -> i32:
    self.starts.get(index as i64)

fn TokenList.get_end(self: TokenList, index: i32) -> i32:
    self.ends.get(index as i64)

// Convenience: construct a Span for token at index with a given file_id.
fn TokenList.get_span(self: TokenList, index: i32, file_id: i32) -> Span:
    Span {
        file: file_id,
        start: self.starts.get(index as i64),
        end: self.ends.get(index as i64),
    }

// Also expose a keyword_lookup alias for the lexer.
fn keyword_lookup(text: str) -> i32:
    tag_from_keyword(text)
