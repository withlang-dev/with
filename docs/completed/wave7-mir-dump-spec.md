# Wave 7 MIR Dump Specification

This document defines the deterministic text format emitted by
`with check <file.w> --dump-mir`.

## Header

The first line is:

```
mir module functions=<N>
```

Where `<N>` is the number of lowered function bodies in declaration order.

## Function Section

Each function body is printed as:

```
fn <name> {
  locals:
    _0: <Type>  // return
    _1: <Type> [mut]  // <user_name>

  bb0: {
    ... statements ...
    ... terminator ...
  }
}
```

Rules:

- Functions appear in source declaration order.
- Locals appear in allocation order.
- `_0` is always the return place.
- User variable names are rendered as trailing comments when available.

## Statements

Supported statement render forms:

- `<place> = <rvalue>;`
- `StorageLive(_<id>);`
- `StorageDead(_<id>);`
- `drop(<place>);`
- `nop;`

## Terminators

Supported terminator render forms:

- `goto -> bb<id>;`
- `return;`
- `unreachable;`
- `switchInt(<operand>) -> [<val>: bb<id>, ..., otherwise: bb<id>];`
- `call <fn>(<args>) -> [return: <place>, next: bb<id>];`
- `drop(<place>) -> bb<id>;`

## Operands and Constants

Operands:

- `copy <place>`
- `move <place>`
- `const ...`

Constants:

- `const <int><type>`
- `const true` / `const false`
- `const "<string>"`
- `const ()`
- `const <float_lexeme>`
- `const zst(<type>)`

## Determinism Requirements

- Output for the same source must be byte-identical across repeated runs.
- No randomized ordering is permitted.
- Formatting and whitespace are fixed by implementation.
