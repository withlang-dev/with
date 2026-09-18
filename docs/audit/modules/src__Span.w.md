# Primary verification — `src/Span.w`

Status: **Complete**  
Primary verifier: root agent  
Source revision: `31f77937abad3bc6573df3b71a0c99b605d6ea8e`  
Source SHA-256: `7253f48f800b87f4005b917302615ce45966f884acc259afa939bee957afb3ff`  
Source examined: all 47 lines

## Scope examined

The complete module was read inline. It defines the root compiler's `FileId`
alias and `Span` value, Copy conformance, zero constructors, range length and
validity queries, and range merging.

The codebase-memory graph was queried first. It is indexed but returned no
symbols or uses for this `.w` module, so Tilth was used for complete source and
consumer discovery.

All 18 direct production imports were enumerated:

- `src/Diag.w`, `src/Diagnostic.w`, `src/Ast.w`, `src/AsyncLower.w`,
  `src/BorrowCfg.w`, `src/Codegen.w`, `src/ComptimeEval.w`,
  `src/ComptimeTransform.w`, `src/Lexer.w`, `src/MirSuspendCheck.w`,
  `src/Parser.w`, `src/Resolve.w`, `src/Sema.w`, `src/SemaDecl.w`,
  `src/SemaDiag.w`, and `src/Token.w`;
- `src/compiler/Compilation.w`; and
- `src/compiler/Frontend.w`.

Every `Span` constructor and direct field use in `src/` was enumerated. The
production compiler constructs and carries spans extensively through tokens,
AST, semantic analysis, MIR diagnostics, analysis output, CLI rendering, and
LSP output. The root module's `len`, `is_valid`, `merge`, `span_zero`, and
`Span.zero` helpers currently have no external production call site. The
parallel foundation `Span.len` is used by foundation diagnostic rendering, and
the foundation helpers are covered by `test/internals/span_source_test.w`.

Applicable overview targets examined: 8, 10, 13–14, 18, 21, 23, and 24. This
module has no allocation, deallocation, platform branch, scheduler behavior,
foreign call, fallback, or generated-output path.

## Source authority comparison

`src/compiler/foundation/Span.w` was read completely. Its data representation
and current computations match the root module, but the modules are independent
implementations rather than a single shared authority. Their APIs already
differ:

- root defines `FileId` locally; foundation imports it from `Ids.w`;
- root adds `Span.zero`; foundation does not;
- root `merge` borrows `other`; foundation takes the Copy value; and
- root validates `file >= 0` directly; foundation calls `file_id_is_valid`.

The current `FileId` definition in `Ids.w` is also an `i32` alias, so these
differences do not presently change runtime results.

## Artifact and optimization evidence

The primary agent ran:

```text
./out/bootstrap/bin/with-stage1 build --explain stage1 :stage1
```

It reported `fresh`, listed `src/Span.w` and
`src/compiler/foundation/Span.w` as separate explicit inputs, and showed the
stage argument `-O1`. No rebuild was performed.

## Behavioral matrix

`docs/audit/probes/span_matrix.w` contains the exact root implementation at the
pinned hash followed by assertions. The primary agent ran both:

```text
with-stage1 check --validate-all docs/audit/probes/span_matrix.w
with-stage1 run docs/audit/probes/span_matrix.w
```

Results were `validate-all: ok` and `span-matrix: ok`.

The matrix covered:

- both zero constructors;
- point, ordinary, and widest-valid ranges;
- negative file, negative start, and reversed endpoints;
- overlapping, disjoint, reversed-order, and cross-file merges;
- minimum/maximum selection branches; and
- Copy behavior while retaining the original value.

The invalid-domain negative control in `docs/audit/probes/span_invalid_len.w`
called `len` on the widest invalid signed range. Checked subtraction rejected
it with exit 134 and `integer overflow: i32 subtraction out of range`. All
valid spans are safe because `0 <= start <= end <= i32::MAX`, so `end - start`
cannot overflow. This is recorded as predictable rejection outside the valid
domain, not a retained defect.

## SPN-001 — cross-file merge manufactures a valid-looking range

Classification: **Confirmed latent correctness defect; candidate unreported**  
Severity: **Low while unused; Medium if the helper gains a caller**  
Blast radius: root and foundation span merging, then any diagnostic or source
consumer that trusts the merged file/range tuple  
Confidence: **Very high**

The executable control merged `{ file: 3, start: 2, end: 8 }` with
`{ file: 9, start: 1, end: 30 }`. It returned
`{ file: 3, start: 1, end: 30 }`, which passes `is_valid()` even though its
range combines offsets from two different files.

Exact source chain:

1. `Span.merge` always copies `self.file` (`Span.w:31-36`).
2. It independently takes the minimum start and maximum end without comparing
   `self.file` and `other.file`.
3. `Span.is_valid` checks only that the retained file is nonnegative and that
   the numeric range is ordered (`Span.w:28-29`).
4. The foundation implementation repeats the same behavior
   (`compiler/foundation/Span.w:25-30`).

Five Whys:

1. The result can point at unrelated bytes because two file-local ranges are
   combined.
2. The operation combines only numeric endpoints and ignores file identity.
3. The return type has no way to signal a file mismatch.
4. No precondition is documented or enforced at the helper boundary.
5. The central span abstraction can therefore create a tuple that satisfies its
   own validity predicate but cannot describe one source range.

Repair boundary: make same-file identity an enforced invariant at the one
canonical merge implementation. A mismatch must fail loudly as an internal
compiler invariant violation or be represented in the return type; it must not
silently select one file. Add same-file point/overlap/disjoint tests and a
cross-file rejection test.

## SPN-002 — root and foundation duplicate the span authority

Classification: **Confirmed architectural risk; candidate unreported**  
Severity: **Medium**  
Blast radius: 18 root-module consumers plus the foundation source/diagnostic
stack  
Confidence: **Very high**

The current build graph compiles both independent implementations. The completed
root-module migration plan states both “Do not maintain two parallel
implementations” and “Replace root modules directly with Wave 1 foundation
implementations,” yet both sources remain and already expose different API
shapes.

Exact cause: `src/Span.w:5-46` redefines the type and every operation while
`src/compiler/foundation/Span.w:3-40` independently defines the corresponding
type and operations. Neither module delegates to the other.

No current result mismatch was found: both implementations use an `i32` file
ID, the same ordered-range predicate, and the same endpoint calculations. The
risk is semantic drift at a central diagnostic boundary, not a presently
observed output failure.

Repair boundary: establish one source module as the type and operation authority
and migrate both consumer sets to it. If language module visibility temporarily
requires two surfaces, one must be a mechanical re-export rather than a copied
implementation, with an executable parity test until the adapter is removed.

## Issue relationship

The primary agent searched the live upstream tracker on 2026-09-02 for `span
merge file`, `Span.merge`, `cross-file span`, `root Span`, `foundation Span`,
and `parallel implementations Span`. No matching report was found. Closed #670
concerned rendering already-existing cross-file diagnostic labels against the
wrong source; it did not cover merging spans or duplicated `Span` authorities.
No issue was filed during this report-only audit.

## Completion statement

The primary agent examined the complete source, the complete parallel
foundation source, every direct production import, every constructor/helper
reference, and the direct field consumers relevant to file/range semantics.
Valid behavior, invalid-domain rejection, Copy behavior, and both retained
findings were verified inline. Artifact inclusion, freshness, and `-O1` were
independently checked. There is no unclassified candidate left in this module,
so this evidence supports marking `src/Span.w` complete while retaining its two
findings for repair prioritization.
