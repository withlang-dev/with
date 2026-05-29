// Spec test: Section 5 — Ephemeral Types.

type ExplicitView = ephemeral {
    view: StrView,
}

fn view_identity(v: StrView) -> StrView:
    v

fn make_explicit_view(v: StrView) -> ExplicitView:
    ExplicitView { view: v }

fn test_ephemeral_local_and_return:
    let v: StrView = "hello"
    let out = view_identity(v)
    assert(out.len() == 5)

fn test_explicit_ephemeral_struct:
    let wrapped = make_explicit_view("world")
    assert(wrapped.view.len() == 5)
