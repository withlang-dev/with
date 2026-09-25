// Repository review trigger, not a language restriction. Compare declarations
// lexically so comments, strings and callback types cannot masquerade as a
// function's own return annotation. Preserve duplicates for overloads/scopes.
use Lexer
use Token

pub fn explicit_unit_returns(text: &str) -> Vec[str]:
    var lexer = Lexer.init(text.slice(0, text.len()), 0)
    let tokens = lexer.tokenize()
    var found: Vec[str] = Vec.new()
    for ti in 0..tokens.len() - 1:
        if tokens.get_tag(ti) != TokenKind.TK_KW_FN or tokens.get_tag(ti + 1) != TokenKind.TK_IDENT: continue
        var depth = 0
        var index = ti + 2
        var signature = "fn " ++ text.slice(tokens.get_start(ti + 1) as i64, tokens.get_end(ti + 1) as i64)
        while index + 1 < tokens.len():
            let tag = tokens.get_tag(index)
            if depth == 0 and (tag == TokenKind.TK_COLON or tag == TokenKind.TK_NEWLINE or tag == TokenKind.TK_EOF): break
            if depth == 0 and tag == TokenKind.TK_ARROW:
                let ty = text.slice(tokens.get_start(index + 1) as i64, tokens.get_end(index + 1) as i64)
                if tokens.get_tag(index + 1) == TokenKind.TK_IDENT and ty == "Unit":
                    found.push(signature ++ " -> Unit")
                break
            if tag == TokenKind.TK_L_PAREN or tag == TokenKind.TK_L_BRACKET: depth = depth + 1
            if tag == TokenKind.TK_R_PAREN or tag == TokenKind.TK_R_BRACKET: depth = depth - 1
            if tag != TokenKind.TK_NEWLINE and tag != TokenKind.TK_INDENT and tag != TokenKind.TK_DEDENT:
                signature = signature ++ " " ++ text.slice(tokens.get_start(index) as i64, tokens.get_end(index) as i64)
            index = index + 1
    found

pub fn added_unit_returns(before: &str, after: &str) -> Vec[str]:
    let old = explicit_unit_returns(before)
    let current = explicit_unit_returns(after)
    var used: Vec[bool] = Vec.new()
    for _ in 0..old.len(): used.push(false)
    var added: Vec[str] = Vec.new()
    for item in current:
        var matched = false
        for i in 0..old.len():
            if not matched and not used[i] and old[i] == item:
                used[i] = true
                matched = true
        if not matched: added.push(item ++ "")
    added

pub fn unit_return_reviewed(reviews: &str, path: &str, signature: &str) -> bool:
    for row in reviews.split("\n"):
        if row.starts_with("#") or row.len() == 0: continue
        let fields = row.split("\t")
        if fields.len() == 3 and fields[0] == path and fields[1] == signature and fields[2].trim().len() > 0: return true
    false
