// D39 emitter refusal fixture: a returned reference with two borrowed
// parameters has no unambiguous origin under the default elision rules;
// --emit-bundle-interface must fail naming `choose` before any consumer
// could see the declaration.
pub type Foo { x: i32 }
pub fn choose(a: &Foo, b: &Foo) -> &Foo: if a.x > b.x: a else: b
pub fn first(a: &Foo) -> &Foo: a
