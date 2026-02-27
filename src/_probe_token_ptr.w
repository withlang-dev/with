use Token

fn add_tok(t: *mut TokenList) -> void:
    TokenList.append(t, TK_EOF(), 0, 0)

fn main:
    var t = TokenList.new()
    add_tok(&t)
    println(i32_to_str(TokenList.len(t)))

extern fn i32_to_str(n: i32) -> str
