# D173 — A name resolves lexically, once; a call of a non-callable local is an error, never a fallback to the function it shadows

**Status:** Ruled (Eric, 2026-10-30).

## Question

A local binding takes the name of a module-scope function:

```
fn first() -> i32: 2
fn main:
    let first = [1, 2]
    print(f"{first()}")
```

The compiler checked the program and then failed in code generation
("BUG: codegen could not emit the terminator", #2006): no stage owned the
meaning of `first` at the call.

## Ruling

> Local variables shadow functions, without fallback. `first` should
> resolve to the local list, and `first()` should be rejected because that
> list isn't callable.
>
> Lexical name resolution should determine what a name means. Whether the
> resulting value can be called is a separate type-checking question.
> Allowing fallback would make the meaning of an identifier depend on how
> it's used, rather than on the scope in which it appears; changing a local
> variable's type could silently change which declaration a call resolves
> to.
>
> The compiler should resolve the identifier once, and all later
> stages—including type checking, interpolation lowering, and code
> generation—must use that same resolution. Name resolution first. Type
> checking second. No fallback based on type.

The diagnostic:

```
error: 'first' is not callable
  'first' resolves to a local binding of type List[i32]

note: this binding shadows the function 'first'
      declared at module scope
```

A regression test uses the example both inside and outside interpolation.
The code-generation crash is a compiler bug.

## Principle

> Inference should remove obligations from programmers, never introduce
> uncertainty about what a program means. The compiler should be ambitious
> about inferring mechanics, but conservative about inventing meaning.

The same principle rules D174 and D175.
