//! expect-stdout: some 1 leaf x

// #1967 follow-up: `fn Wrap.new[T]` lists `T` twice among the parameters
// a specialization binds (the owner's `Wrap[T]` and the function's own
// `[T]`). The frame that installs those bindings saved each one before
// installing it and restored them first to last, so the second save (which
// had read the first binding) was restored last and `T` stayed bound to
// `Option[str]` after `Wrap.new(Some(..))` was checked. With a scoped
// binding ahead of the module's types, the module's `enum T` below then
// read as `Option[str]`: "unknown method 'Leaf' for type 'Option[str]'".

type Wrap[T] { v: T }

fn Wrap.new[T](v: T) -> Wrap[T]: Wrap { v }

enum T:
    Leaf(s: str)
    Node(n: i32)

fn main:
    let w = Wrap.new(Some("maybe".clone()))
    let kids: Vec[T] = Vec.new()
    kids.push(T.Leaf("x".clone()))
    match &kids[0]:
        .Leaf(s) => print(f"{if w.v.is_some(): "some" else: "none"} {kids.len()} leaf {s}")
        .Node(_) => print("node")
