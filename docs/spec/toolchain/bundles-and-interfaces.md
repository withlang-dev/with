# 18.5c Bundles and interfaces

A bundle is a migrated corpus compiled once (docs/spec/toolchain/wo_bundles.md, decisions
D38, D39): object code, a manifest, a canonical textual module interface
(.wi), and an interface fingerprint, keyed by corpus content, target, and
the ABI identity `with version --abi-sha` prints. The compiler embeds the
bundles it ships and links into a program exactly the bundles the program
references; the program is standalone.

A module a bundle provides resolves to its .wi, not its source. A .wi is
ordinary With declaration syntax in an interface-only mode: a function may
omit its body and a storage-backed global may omit its initializer only in
interface input; in ordinary source both remain errors. A constant in an
interface carries its folded value. Callable semantics of an interface
declaration are determined by the declared signature alone (§3.8): a plain
`T` parameter is consumed, `&T` is borrowed for the call, receiver modes as
written, raw pointers carry no ownership; no body-inferred information is
part of an interface. A generic function does not cross the boundary: it
stays internal to its corpus and is omitted from the interface, which
names it. A `comptime fn` crosses the boundary with its body, and with the
body of every function of its package that it reaches: the importer
evaluates them. A `comptime fn` whose compile-time answer the compiler
supplies crosses as a declaration without a body. *(Status: implemented for
a tree bundle, for functions and methods; a body in an interface is
accepted only on a function one of its `comptime fn`s reaches. A stored
bundle carries only the declaration form.)*
The bundle build proves that the interface yields the same
exported declaration model as the source, records that fingerprint in the
manifest, and rejects a mismatch before linking.
