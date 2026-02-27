//! expect-stdout: ok

use Token

fn main:
    // Keyword lookup
    assert(keyword_lookup("fn") == TK_KW_FN())
    assert(keyword_lookup("let") == TK_KW_LET())
    assert(keyword_lookup("true") == TK_TRUE())
    assert(keyword_lookup("false") == TK_FALSE())
    assert(keyword_lookup("not_a_keyword") == -1)
    assert(keyword_lookup("hello") == -1)

    // Token list
    var tl = TokenList.new()
    TokenList.append(tl, TK_KW_FN(), 0, 2)
    TokenList.append(tl, TK_IDENT(), 3, 7)
    TokenList.append(tl, TK_COLON(), 7, 8)
    assert(TokenList.len(tl) == 3)
    assert(TokenList.tag_at(tl, 0) == TK_KW_FN())
    assert(TokenList.tag_at(tl, 1) == TK_IDENT())
    assert(TokenList.start_at(tl, 1) == 3)
    assert(TokenList.end_at(tl, 1) == 7)

    println("ok")
