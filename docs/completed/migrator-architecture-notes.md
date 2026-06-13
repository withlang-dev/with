# Migrator Architecture Notes

This note records the current C migrator architecture problem found while
working on the full `--emit-c` roundtrip:

1. Build the With compiler normally.
2. Emit the compiler to C.
3. Build the emitted C compiler.
4. Migrate the emitted C back to With.
5. Build and test the migrated compiler.
6. Use the migrated compiler to rebuild the compiler.
7. Compare the rebuilt compiler byte-for-byte with the original.

The immediate symptom is high memory use while migrating the emitted compiler C
file. The emitted C file is large, around 1.1M lines and 24.5 MB, but the
migrator process reaches roughly 20 GB RSS. That is not a hard blocker on a
machine with 128 GB RAM, but it is strong evidence that the migrator has the
wrong ownership model for a translation this large.

## What We Learned

The runtime allocator is a freelist allocator backed by `mmap`.

- Payloads larger than 4096 bytes are direct `mmap` allocations and are returned
  to the OS with `munmap`.
- Payloads up to 4096 bytes are allocated from 64 KiB slabs.
- `with_free` for small allocations puts the block on a freelist.
- Small allocation slabs are never unmapped.

This means RSS is not the same as live memory. A correct `deinit` can make memory
reusable without reducing RSS. For this reason, RSS alone cannot tell us whether
the migrator is leaking live objects or simply reusing retained allocator slabs.

Even with that caveat, the architecture is still wrong: the migrator retains too
many temporary facts for the lifetime of the whole translation unit.

## Zig Comparison

The useful reference points are:

- `.reference/translate-c/src/main.zig`
- `.reference/translate-c/src/Translator.zig`
- `.reference/translate-c/src/Scope.zig`
- `.reference/zig/src/link/C.zig`
- `.reference/zig/src/codegen/c.zig`

Zig's standalone `translate-c` uses Aro's C parser and preprocessor. It owns a C
tree, macro token streams, source buffers, and type data directly. Translation
works over structured nodes and slices into source/interner storage. It does not
repeatedly ask libclang for stringified cursor/type/source facts through a bridge.

Zig's C backend also stores rendered output as chunks:

- function code is rendered into a temporary per-function buffer,
- finished declarations are copied into shared byte storage,
- output keeps slice references into that storage,
- final flush writes a vector of buffers in dependency order.

The important lesson is not that With must copy Zig's exact data structures. The
lesson is lifetime discipline:

- structured facts should stay structured;
- strings should only be allocated when rendering actually needs strings;
- temporary render/query strings should have a short lifetime;
- whole-translation lifetime should be reserved for facts that are genuinely
  needed until the end.

## Current With Problem

The current libclang bridge has a broad session-owned string model.

Many APIs do this:

1. Ask libclang for a spelling, type spelling, location string, source snippet,
   expansion text, or translated type.
2. Copy the result with `session_make_str`.
3. Store the allocation in `CImportSession.strings`.
4. Free it only in `with_cimport_dispose`.

That makes every returned string live for the whole translation unit. On a small
header this is acceptable. On a 1.1M-line emitted compiler C file, repeated
queries turn temporary strings into process-wide retained memory.

The worst pattern is not a single large object. It is cumulative small-object
retention:

- cursor spelling queries,
- type spelling and translated-type queries,
- source text queries,
- location formatting,
- expansion text,
- macro helper strings,
- per-function lowering strings copied through IR pools.

Because the allocator also retains small freed blocks in slabs, a session string
storm shows up as both high live memory and a high RSS floor.

## Non-Causes

The macro value string is poorly designed, but it is not the current 20 GB
explanation for the emitted compiler input.

For the current emitted compiler C file, `clang -E -dM` reports roughly:

- 2,763 macro definitions,
- 216 KiB of macro text.

`g_migrate_macro_values` should still be replaced with structured storage, but it
is not credible as the dominant memory retainer in this case.

Likewise, the input C source is only around 24.5 MB. Source and preprocessed
source buffers are not the dominant cause unless preprocessing expands them by
orders of magnitude, which has not been observed.

## Design Goals

The migrator should satisfy these constraints:

1. Querying a cursor or type should not allocate a new session-lifetime string
   every time.
2. Common bridge facts should be represented as structured IDs, integers, ranges,
   and interned names.
3. Strings that are needed only while translating one declaration or function
   should be allocated in a scoped scratch arena and released after that unit.
4. Whole-session storage should contain unique, reusable facts, not duplicate
   query results.
5. Macro storage should be structured and indexed, not a concatenated string.
6. Output should be chunked and flushed, not repeatedly rebuilt with large string
   concatenations.
7. Unsupported translation should fail loudly. Architecture cleanup must not
   introduce silent stubs or lossy fallbacks.

## Proposed Architecture

### 1. Split Bridge Results By Lifetime

Introduce three explicit bridge result lifetimes:

```with
type CiLifetime = enum {
    Borrowed,
    Scratch,
    Session,
}
```

The important part is not necessarily this exact enum; the important part is
that APIs communicate ownership.

Use these categories:

- **Borrowed:** slices or IDs that point into stable source/session storage and
  do not need copying.
- **Scratch:** temporary text valid until the current scratch arena is reset.
- **Session:** unique facts intentionally retained until `with_cimport_dispose`.

Most current `session_make_str` call sites should become either borrowed or
scratch. Session ownership should be the exception.

### 2. Add Per-Translation Scratch Storage

Add a scratch arena or scratch string list to the bridge or migrator.

Required operations:

```with
extern fn with_cimport_scratch_mark(session: i64) -> i64
extern fn with_cimport_scratch_restore(session: i64, mark: i64) -> void
extern fn with_cimport_scratch_reset(session: i64) -> void
```

Usage pattern:

```with
let mark = with_cimport_scratch_mark(session)
// translate one declaration, function, statement, or expression
with_cimport_scratch_restore(session, mark)
```

The granularity should start at one top-level declaration. If function bodies
still retain too much, lower the granularity to statement or expression
translation.

Scratch storage does not need to return RSS to the OS on every reset. It must
allow reuse and must cap the amount of live scratch data needed at one time.

### 3. Replace Repeated String Queries With Cached Facts

For common cursor and type queries, cache once per cursor/type index.

Examples:

```with
type CiCursorInfo {
    kind: i32,
    spelling: str,
    type_id: i32,
    start_offset: i32,
    end_offset: i32,
    file_id: i32,
    line: i32,
    column: i32,
}

type CiTypeInfo {
    kind: i32,
    canonical_id: i32,
    pointee_id: i32,
    translated: str,
}
```

The exact fields should follow current call-site needs. The key rule is:

> If a fact is asked many times, the bridge computes it once and returns a stable
> cached result. It does not allocate a new string per query.

This also makes instrumentation easier: cache sizes are visible and bounded by
cursor/type counts.

### 4. Prefer IDs And Ranges Over Strings

Many current bridge APIs return strings because that was the easiest boundary to
wire.

Replace them with structured APIs where possible:

- source text: return `(start_offset, end_offset)` and let the migrator slice the
  original source when needed;
- location: return `{ file_id, line, column }`, not `"file:line:column"`;
- cursor spelling: return an interned string ID or cached spelling;
- type identity: return type IDs, canonical type IDs, and kind integers;
- macro values: return macro IDs and token ranges.

Rendering can turn these facts into strings at the edge.

### 5. Replace Macro Value String With A Map

Replace:

```with
g_migrate_macro_values: str = "|NAME=value|..."
```

with structured storage:

```with
type CiMacroInfo {
    name: str,
    value: str,
    is_fn_like: bool,
}

var g_migrate_macro_values: HashMap[str, CiMacroInfo]
var g_migrate_macro_misses: HashMap[str, bool]
```

or an equivalent deterministic structure if `HashMap` ordering is a concern.
Lookup should be O(1) or O(log n), and adding a value must not copy all previous
macro values.

This is probably not the dominant memory issue for the emitted compiler input,
but it is still the correct representation.

### 6. Chunk Migrator Output

Keep the current `Vec[str]` direction, but tighten it:

- no large `output = output ++ part` loops;
- no per-category mega strings such as all globals in one mutable `str`;
- each top-level declaration returns a chunk;
- final write should prefer writing chunks directly, or join only once at the
  last possible moment if the file API requires it.

Longer term, mirror Zig's C backend shape:

- one backing byte buffer for generated chunks;
- chunk descriptors as `{ start, len }`;
- dependency/order pass over chunk descriptors;
- vector write at flush.

### 7. Keep Translation Structured Internally

The migrator currently mixes:

- libclang cursor traversal,
- string queries,
- ad hoc expression rendering,
- IR lowering,
- output text generation.

The long-term target should be:

```text
libclang/Aro facts -> Ci AST/IR -> With AST/IR -> renderer
```

String output should happen at the final renderer boundary. Intermediate phases
should pass typed nodes and IDs.

This is the deeper version of the same lesson from Zig's translator: avoid
stringifying the source language too early.

## Instrumentation Before Behavior Changes

Before changing the bridge lifetime model, add accounting so we can prove the
effect of each step.

Minimum counters:

- allocator mapped bytes;
- allocator live payload bytes;
- allocator peak live payload bytes;
- small allocation slab bytes;
- large allocation live bytes;
- bridge session string count;
- bridge session string payload bytes;
- bridge scratch string count/bytes;
- cursor/type/child array capacities;
- macro count and macro value bytes.

Print these at controlled migration checkpoints:

1. after parsing the main session;
2. after macro capture;
3. after top-level declaration translation;
4. after macro translation;
5. after disposing libclang sessions;
6. after output write.

This distinguishes:

- live retained data,
- allocator-retained freed slabs,
- libclang-owned memory,
- bridge-owned session strings,
- migrator output buffers.

## Implementation Plan

### Phase 1: Measure

Add the counters above. Do not change behavior.

Expected result: identify whether most retained memory is:

- bridge session strings,
- allocator slabs from already-freed transient strings,
- libclang translation-unit memory,
- output chunks,
- some other pool.

### Phase 2: Cache Common Bridge Facts

Add per-cursor/per-type caches for the most common string-returning APIs:

- cursor spelling;
- cursor location;
- cursor source range;
- cursor source text, if still needed;
- type spelling;
- translated type.

Repeated calls must return cached storage.

This phase is low risk because it preserves the existing API surface while
removing duplicate session allocations.

### Phase 3: Add Scratch Lifetime

Introduce scratch allocation APIs and move temporary bridge strings to scratch.

Candidate scratch APIs:

- cursor source text;
- cursor expansion text;
- formatted locations;
- temporary translated type strings used only during one lowering step.

Reset scratch at top-level declaration boundaries first. Tighten later if
measurements show function/statement granularity is needed.

### Phase 4: Replace Macro Storage

Replace `g_migrate_macro_values` and `g_migrate_macro_miss_names` with
structured maps or deterministic indexed storage.

This is correctness and maintainability work more than the expected 20 GB fix.

### Phase 5: Chunk Output Fully

Remove remaining large string concatenation loops in migration output paths.

Start with:

- `ci_migrate_translate_vars`;
- struct/enum/typedef translation helpers that repeatedly append to `str`;
- macro translation output.

End state: output is a list of chunks with a single final write path.

### Phase 6: Reduce Dependence On Stringified Libclang

Replace bridge APIs that return rendered text with APIs that return structured
facts.

Examples:

- use source ranges instead of source text;
- use location structs instead of formatted location strings;
- use type IDs and kind fields instead of type spelling where possible;
- use macro token streams instead of macro value text.

This phase is the durable architecture. It moves With closer to the Zig/Aro
model without requiring an immediate C parser rewrite.

## Expected Outcome

The short-term goal is not necessarily low RSS. With the current allocator, RSS
may remain high even when live memory improves. The short-term goal is bounded
live memory and stable migration progress on the emitted compiler C file.

The medium-term goal is to make the emitted compiler roundtrip practical:

```text
With compiler -> emitted C compiler -> migrated With compiler -> byte-identical compiler
```

The long-term goal is a C migrator whose implementation is based on structured
translation, not string lifetime accidents.

