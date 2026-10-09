# Length width: fixed signed lengths with a bounded range

Status: decision brief; no ruling or implementation change. Companion to the [Goose study](goose.md).

[D11](../meetings/2026-07-17-D11-collection-length-is-signed-len-int-i64-no-option-wrapper-c.md) already rules that collection lengths, counts and positions use `Int` (`i64`). Signed arithmetic makes an empty collection's `len() - 1` equal `-1`; absence remains `Option`, and C error sentinels belong to modeled bindings. Layout `size` and `align` remain `usize`. The question here is whether to preserve that width while making the valid length range an enforced compiler fact.

| Option | Contract | Consequence |
|---|---|---|
| Fixed `i64`, without a tighter language bound | A length is non-negative and fits `i64`; allocators impose their own limits. | Preserves D11 and platform-independent arithmetic. Narrow-target C conversion still needs a range proof/check. |
| Target-width `isize` | A length fits the positive range of the target's signed pointer integer. | Conversion to `size_t` preserves values, but changes source arithmetic width and narrows usable counts. Requires reopening D11. |
| Fixed `i64`, with a stated target-bounded range | Every collection length satisfies `0 <= len <= L(target)`, with `L(target) <= 2^48` and `L(target) <= SIZE_MAX`. | Preserves D11's width and signed difference arithmetic while proving a length-to-`size_t` conversion value-preserving. |

**Recommendation: the third option.** Keep `Int`, specify the maximum separately, and enforce it at producers. A conservative policy is `L(target) = min(2^48, SIZE_MAX)`; actual object and allocator limits may be smaller. The ceiling is a limit, not a promise that a collection of that size can be allocated. Decide the inclusive endpoint explicitly: Goose's BCE uses an inclusive upper bound, which is different from saying lengths fit in 48 unsigned bits.

Goose supplies an implementation precedent, with an important qualification. [`BCE::LENMAX` and the length-base edges in `DistsFrom`](../../.reference/goose/src/bce.h) attach a non-negative, bounded length fact; [`runtime.h`](../../.reference/goose/src/runtime/runtime.h) rejects stack reservations above `2^48`. This is a range invariant on length-producing operations, **not** a refinement of every variable whose type is `i64`. A plain `i64` can still be negative. Goose's local-stack limit does not by itself prove With's independently allocated collections satisfy the same bound.

The ruling should require constructors, growth, concatenation, slices, deserialization, foreign adapters, iterator counts and zero-sized-element collections to preserve the invariant. Test `0`, the ceiling, and ceiling-plus-one without allocating enormous buffers, through checked arithmetic or synthetic producer tests. Multiplication must be checked *before* allocation: a valid element count does not prove `count * stride` fits `size_t`, the allocator's limit, or pointer-offset arithmetic. Capacity and byte length need their own enforced bounds; `position` must be below the corresponding collection length.

At modeled C boundaries, a proven collection length may convert to the actual target's unsigned size type without a user-written cast. An arbitrary `i64`, a negative foreign result, or a derived byte count without a multiplication proof may not. Foreign results must be validated before entering the collection-length domain. This does not infer ownership, retention, success or destruction, and cannot weaken [D51](../meetings/Ruling-modeled-C-ownership-effects-conventions-and-foreign-lifetimes.md).

This changes the answer about width: target-width arithmetic is unnecessary to obtain lossless C length conversion. It does **not** yet justify deleting conversion checks from the compiler. First inventory and verify every producer, give the length fact one semantic owner, and carry it to conversion and BCE. Representation alone is not proof.
