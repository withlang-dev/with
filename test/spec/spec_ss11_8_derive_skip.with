//! expect-stdout: ok
// §11.8.1.15/16: derive(all) derives every eligible trait and silently SKIPS
// ineligible ones (no Default here); it never infers Copy.
@[derive(Eq, Clone)]
type Inner { x: i32 }
@[derive(all)]
type Container { inner: Inner }
fn main:
    assert(comptime Container.implements(Eq))
    assert(comptime Container.implements(Key))
    assert(comptime Container.implements(Clone))
    assert(not comptime Container.implements(Default))
    print("ok")
