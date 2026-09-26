//! expect-stdout: E
//! expect-stdout: t=3
//! expect-stdout: E
//! expect-stdout: E
//! expect-stdout: E
//! expect-stdout: n
//! expect-stdout: 5
//! expect-stdout: a=3
//! expect-stdout: b=E

// #1506 / #1558: a payloadless variant of a user generic enum is typed by
// the expected type (§4.6) — an argument, an annotated binding, `.E`, an
// if-arm — and by its payload when nothing expects a type. It was typed as
// the uninstantiated `G`, which has no representation ("aggregate rvalue
// missing destination struct type").

enum G[T]:
    V(t: T)
    E

enum Maybe[T]:
    Just(T)
    Nothing

fn g_text(g: G[i64]) -> str:
    match g:
        G.V(t) => f"t={t}"
        G.E => "E".clone()

fn maybe_text(m: Maybe[i32]) -> str:
    match m:
        Just(v) => f"{v}"
        Nothing => "n".clone()

fn main:
    print(g_text(G.E))
    print(g_text(G.V(3)))
    let e: G[i64] = G.E
    print(g_text(e))
    let e2: G[i64] = .E
    print(g_text(e2))
    let e3: G[i64] = if true: G.E else: G.V(1)
    print(g_text(e3))
    let nothing: Maybe[i32] = Maybe.Nothing
    print(maybe_text(nothing))
    print(maybe_text(Maybe.Just(5)))
    let a = G.V(3)
    match a:
        G.V(t) => print(f"a={t}")
        G.E => print("a=E")
    let b: G[i64] = G.E
    match b:
        G.V(t) => print(f"b={t}")
        G.E => print("b=E")
