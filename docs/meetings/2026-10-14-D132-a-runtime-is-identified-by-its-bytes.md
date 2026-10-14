# D132 — A runtime object set is the linking compiler's when its objects are the bytes that compiler embeds, whoever compiled them

**Date:** 2026-10-14. **Status:** ruled (Eric). **Narrows:** #1815's reading
of D30, which refused every object set another generation recorded.

**Ruling (Eric, 2026-10-14).** Asked why the runtime, which almost never
changes, is rebuilt and refused so often, and given the cause and the fix
("key the runtime directory on its content: a compiler accepts runtime
objects that are byte-identical to the runtime it embeds; the release build
never deletes a runtime it cannot replace"): "fix it".

**Decision.**

- A link accepts a runtime directory when its `.producer` names the linking
  compiler's generation, or when every host runtime object the directory
  holds is byte for byte the one the compiler embeds and that embedded
  runtime is the compiler's own generation's (stage1 embeds the seed's, so a
  stage1 never vouches this way). Anything else is refused as before.
- The LLVM and Clang bridges are embedded nowhere, so nothing vouches for
  their bytes: they still need the generation.
- Stage1 no longer deletes `out/lib`'s runtime objects. The deletion predates
  #1815, when a seed could prefer `out/lib`; every seed now checks the
  generation and stage1 names its root.

**Why.** A generation is the sha256 of every `.w` under `src/` and `rt/`
(`build/compiler.w compiler_generation`), so a comment edit anywhere in the
compiler made the last build's runtime another generation's, though
recompiling it gave the same bytes. A driver built from the edited tree then
had no runtime root to link its action runner against and evaluated every
action at comptime, where several of this tree's actions do not evaluate.
The stage1 deletion made it worse: a nested build that rebuilt stage1
emptied `out/lib` under the lanes linking through it.

D30's blessed text is the test: an object is admissible as a cache "where a
hit is byte-identical to the in-unit result". Identical bytes are not a mixed
world; #761's corruption came from objects whose bodies differed.

**What would reopen it.** A runtime whose correctness depends on something
outside its object bytes (a side table, a separately shipped header), or a
second embedding path whose objects the comparison does not cover.
