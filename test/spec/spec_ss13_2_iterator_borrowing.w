// Spec test: Section 13.2 — Iterator Borrowing (formerly 25.75)
// Negative iterator-retains-source coverage lives in:
//   - test/compile_errors/err_iter_of_self_vec_iter.w
//   - test/compile_errors/err_iter_of_self_hashmap_keys.w

type Token { text: str }

type TokenStream { index: i32 }

impl Iter[Token] for TokenStream =
    fn next(mut self: Self) -> Option[Token]:
        if self.index == 0:
            self.index = 1
            return .Some(Token { text: "let" })
        if self.index == 1:
            self.index = 2
            return .Some(Token { text: "value" })
        .None

fn token_text(tok: Token) -> str:
    tok.text

fn test_stdlib_iterator_next_twice:
    let names: Vec[str] = Vec.new()
    names.push("alice")
    names.push("bob")
    names.push("charlie")
    let iter = names.iter()
    let a = iter.next().unwrap()
    let b = iter.next().unwrap()
    assert(a == "alice")
    assert(b == "bob")
    assert(names.len() == 3)

fn test_for_loop_with_custom_owned_iterator:
    let stream = TokenStream { index: 0 }
    var text = ""
    for tok in stream:
        text = text ++ token_text(tok)
    assert(text == "letvalue")

fn test_collect_owned_tokens_from_custom_iterator:
    let stream = TokenStream { index: 0 }
    let tokens = with Vec.new() as mut toks:
        for tok in stream:
            toks.push(tok)
    assert(tokens.len() == 2)
    assert(tokens.get(0).text == "let")
    assert(tokens.get(1).text == "value")
