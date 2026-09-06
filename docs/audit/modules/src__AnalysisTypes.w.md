# Primary verification — `src/AnalysisTypes.w`

Status: **Complete**  
Primary verifier: root agent  
Source revision: `31f77937abad3bc6573df3b71a0c99b605d6ea8e`  
Source SHA-256: `0b5496944f8de7561de71c8f2ee6f8b26e9cea77e91c73661975ec2ab1a733ff`  
Source examined: all 475 lines

## Scope examined

The complete module was read inline. It defines the stable analysis fact schema,
receiver/marshal enums, owned report copying and merging, query parsing and
matching, TSV escaping, filtered fact/summary/matrix rendering, and verdict
rendering.

Every repository consumer was traced. Direct consumers are:

- `src/Analysis.w` — all Sema/MIR/diagnostic fact production and command rendering;
- `src/Codegen.w` and `src/CodegenTraits.w` — ABI/codegen fact production;
- `src/compiler/Backend.w` and `src/compiler/Compilation.w` — backend report
  construction and report merging;
- `src/ReceiverMigration.w` — declaration flags and receiver-mode consumers; and
- `src/main.w` — diagnostic severity consumer.

The codebase-memory graph was queried first and returned no `.w` symbols for the
module. Tilth was then used to enumerate every textual definition and consumer.
`analysis_required_receiver_mode`, `analysis_receiver_keyword`, and
`AnalysisReport.count_matching` have no repository consumer; this is recorded as
dead surface, not promoted to a correctness defect.

Applicable overview targets examined: 1–3, 8–10, 14, 18, 21, 23, and 24.
The module has no platform branch, allocator primitive, runtime scheduler path,
or backend-specific representation.

## Artifact and optimization evidence

Primary execution of:

```text
./out/bootstrap/bin/with-stage1 build --explain stage1 :stage1
```

reported `fresh`, `-O1`, and listed `src/AnalysisTypes.w` as an explicit stage1
input. All executable controls below used that stage1 at the pinned revision.

## Working controls

Against `test/spec/spec_ss14_11_await_combinator_cancel_joins.w`, the primary
agent ran all documented query operators:

| Query | Exit | Matching facts |
|---|---:|---:|
| `summary:stage=mir` | 0 | 7005 |
| `summary:stage!=mir` | 0 | 4867 |
| `summary:name~await` | 0 | 1401 |
| `summary:flags&=512` | 0 | 144 |
| `summary:stage=sema,kind=call` | 0 | 50 |

`select`, `summary`, `matrix`, and verdict rendering were exercised. The
codegen report/merge path was exercised with `audit:codegen` on
`test/phase/validate_all_basic.w`; it exited 0 without a report ownership crash.

## ATY-001 — malformed predicates fail open

Classification: **Confirmed defect; candidate unreported**  
Severity: **High**  
Blast radius: every `select:`, `summary:`, `matrix:`, `explain:`, LLDB recipe,
and codegen-analysis query  
Confidence: **Very high**

Primary executable results:

| Query | Exit | Result |
|---|---:|---|
| `summary:nonesuch=` | 0 | all 11,872 facts |
| `summary:nonesuch!=x` | 0 | all 11,872 facts |
| `summary:nonesuch=x` | 0 | zero facts |
| `summary:flags&=x` | 0 | all 11,872 facts |
| `summary:stage~` | 0 | all 11,872 facts |
| `summary:,` | 0 | all 11,872 facts |

Exact source chain:

1. `analysis_fact_field` returns `""` for an unknown field instead of reporting
   an invalid query (`AnalysisTypes.w:307-328`).
2. `analysis_parse_i32` returns `0` for an invalid numeric operand
   (`AnalysisTypes.w:273-286`).
3. `analysis_term_matches` treats those sentinel values as real data: an empty
   substring matches every string, a zero bitmask matches every integer, and an
   unknown empty-valued field equals the empty string (`330-355`).
4. `analysis_fact_matches` silently skips empty comma terms (`357-373`).
5. The Analysis and Codegen entry points accept the resulting Boolean without a
   parse-status channel.

Five Whys:

1. A malformed query can return a plausible green result because it becomes a
   valid matcher.
2. It becomes valid because parse failures are encoded as ordinary empty/zero
   values.
3. The matcher cannot distinguish missing data from invalid syntax.
4. The command path has no validated query representation or error result.
5. Consequently the primary debugging/audit surface can silently redefine what
   evidence was selected.

Repair boundary: parse the full query once into a validated predicate structure.
Field names and operators must be enumerated, operands must be non-empty where
required, integer parsing must return an error, and any malformed term must emit
a source query diagnostic and exit nonzero. Matchers must never encode parse
failure as data.

## ATY-002 — an overflowing numeric predicate panics the compiler

Classification: **Confirmed defect; candidate unreported**  
Severity: **Medium**  
Blast radius: numeric equality and bitmask operands accepted by `with analyze`  
Confidence: **Very high**

Primary reproduction:

```text
with-stage1 analyze <fixture> 'summary:flags&=2147483648'
exit 134
panic: integer overflow: i32 addition out of range
```

The exact wrong operation is `value = value * 10 + ch - 48` in
`analysis_parse_i32` (`AnalysisTypes.w:280-285`). User-provided query text is
accumulated in checked `i32` arithmetic with neither a range check nor an error
return.

Five Whys:

1. The compiler aborts because decimal accumulation overflows `i32`.
2. Overflow is reachable because the query operand length/value is unrestricted.
3. Parsing returns only `i32`, so it cannot distinguish invalid or out-of-range
   input.
4. Query validation is fused into matching rather than completed at the command
   boundary.
5. A debugging command therefore turns ordinary invalid input into a process
   panic instead of an actionable diagnostic.

Repair boundary: the same validated-query parser required by ATY-001 must use
checked accumulation and return a nonzero diagnostic on overflow. A panic guard
around this one expression would leave every other malformed-query path intact.

## ATY-003 — filtered matrices report the unfiltered fact count

Classification: **Confirmed verification defect; candidate unreported**  
Severity: **High**  
Blast radius: every `matrix:<query>` result from semantic and codegen analysis  
Confidence: **Very high**

Primary differential control on `test/phase/validate_all_basic.w`:

```text
summary:stage=codegen
facts 0

matrix:stage=codegen
<header, no rows>
compiler-analysis: facts=8553 violations=0 ok
```

`matrix:stage=nonesuch` produces the same zero-row matrix followed by
`facts=8553 ... ok`.

Exact source chain:

1. `render_matrix(query)` correctly filters emitted rows
   (`AnalysisTypes.w:443-459`).
2. `compiler_analysis_render` concatenates that filtered matrix with
   `render_verdict` (`Analysis.w:1928`). Codegen does the same
   (`Codegen.w:618-621`).
3. `render_verdict` has no query and reports `self.facts.len()`
   (`AnalysisTypes.w:461-475`).
4. The existing `count_matching(query)` helper is unused.

Five Whys:

1. A zero-row matrix claims thousands of facts because the footer counts the
   whole report.
2. The count is whole-report because verdict rendering is query-unaware.
3. Filtering and verdict construction are separate calls with no shared result.
4. The output schema does not distinguish total facts from matched facts.
5. An evidence-oriented command can therefore present an internally
   contradictory success summary.

Repair boundary: filtered rendering must compute and carry the matched count
once. The footer must label both total and matched counts if both are useful,
and the scope of violations must be explicit. Empty matrices need an unambiguous
`matched=0`, never an unrelated fact count.

## Issue relationship

The primary agent searched the live upstream tracker for `analysis query unknown
field`, `audit query field`, and `summary select analysis` on 2026-09-01. No
matching issue was found. #742 concerns violations reported by `audit:all`, not
query parsing or filtered rendering. ATY-001 through ATY-003 remain candidate
unreported issues; no issue was filed during this report-only audit.

## Required regression matrix

- Every documented field with `=`, `!=`, `~`, and `&=` where applicable.
- Unknown field, unknown operator, missing field, missing operand, empty term,
  leading/trailing/doubled comma, invalid integer, negative integer, `i32`
  boundaries, and overflow.
- `select`, `summary`, `matrix`, `explain`, LLDB recipes, and codegen matrices.
- Zero, one, and many matches; footer total/matched/violation counts must agree
  with emitted rows.
- Tabs, backslashes, CR/LF, and empty strings in path/name/detail TSV fields.
- Report merge with zero/many facts, notes, and violations, followed by drop
  under the native debug allocator.

## Completion statement

The module's complete source and every repository consumer were examined by the
primary agent. Valid operator controls and all three retained findings were run
inline. Artifact inclusion and `-O1` freshness were independently checked. The
module contains no unresolved candidate whose source branch or executable status
was left unclassified. This evidence supports checking this module complete even
though its confirmed defects remain open for later repair.
