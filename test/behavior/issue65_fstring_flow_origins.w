//! expect-stdout: ok

error E =
    Bad(msg: str)
    Missing(path: str, line: i32)
    Empty

enum Token { Int(i32) | Text(str) | End }

type Holder {
    err: E,
    tok: Token,
}

type Nest {
    holder: Holder,
}

fn helper_err(msg: str) -> E:
    E.Bad(msg)

fn helper_tok(n: i32) -> Token:
    Token.Int(n)

fn main:
    let helper = helper_err("helper")
    assert(f"{helper}" == "Bad(helper)")

    let if_err = if false: E.Empty else E.Bad("if-else")
    assert(f"{if_err}" == "Bad(if-else)")

    let match_err = match false:
        true => E.Empty
        false => E.Bad("match")
    assert(f"{match_err}" == "Bad(match)")

    let match_empty = match true:
        true => E.Empty
        false => E.Bad("unused")
    assert(f"{match_empty}" == "Empty")

    let holder = Holder { err: E.Missing("cfg.w", 7), tok: helper_tok(42) }
    assert(f"{holder.err}" == "Missing(cfg.w, 7)")
    assert(f"{holder.tok}" == "Int(42)")

    let nest = Nest { holder: Holder { err: E.Empty, tok: Token.Text("nest") } }
    assert(f"{nest.holder.err}" == "Empty")
    assert(f"{nest.holder.tok}" == "Text(nest)")

    let errs: Vec[E] = Vec.new()
    errs.push(E.Bad("vec"))
    assert(f"{errs.get(0)}" == "Bad(vec)")

    let toks: Vec[Token] = Vec.new()
    toks.push(Token.Text("bag"))
    assert(f"{toks.get(0)}" == "Text(bag)")

    print("ok")
