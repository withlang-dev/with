# COBOL → With Migration Plan

## Authority and scope

Plan of record for extending `with migrate` from C to COBOL. Direction
set by Eric (2026-08-31); the open forks below (front end, beachhead
corpus) need his explicit ruling before their stages start. This plan
cannot amend the spec or the migrate doctrine — it applies them.

The governing doctrine is unchanged from the C migrator:

- **No silent fallbacks.** A construct the translator cannot lower is a
  loud diagnostic naming the program, paragraph, and clause, and a
  non-zero exit — never a stub, never a "simplified" behavioral change.
  A migrator that converts 90% of programs perfectly and refuses the
  rest loudly is a product; 100% with goto-soup is not.
- **Output must be maintainable.** This is the entire market gap. The
  existing COBOL translators (Blu Age/AWS, Heirloom, TSRI, Astadia)
  produce target-language code shaped like COBOL and locked to vendor
  runtime frameworks. The bar here is idiomatic With a human would
  accept in review — paragraphs become functions, `EVALUATE` becomes
  `match`, level-88s become predicates, not emulation calls.
- **Validate by dual run, never by eyeball.** Original and migrated
  programs run on the same inputs; outputs compare bit-exact. The NIST
  COBOL-85 validation suite (CCVS) is the public acceptance matrix,
  tracked count-first like the drop audit.

## Why this market, why With

COBOL modernization offers three bad options today: rehost (Micro
Focus/Rocket — keep COBOL, pay per-core forever; the business OpenText
sold to Rocket for ~$2.3B in 2024), rewrite (fails famously), or
translate into unmaintainable framework-locked Java/C#. Nobody ships
maintainable, framework-free, native output. The gap is a
*maintainability* problem, which is the axis the migrate discipline is
built on.

With is an unusually good target — better than the JVM/.NET targets the
incumbents use:

| COBOL | With |
|---|---|
| record (01-level group) | struct |
| `REDEFINES` | anonymous union (in-tree since the zlib/pcre2 campaigns) |
| `PIC X(n)` fixed alpha | `std.fixed_string` |
| level-88 condition names | predicate methods / enums |
| `EVALUATE` | `match` |
| paragraphs / `PERFORM` | functions / calls |
| `PIC S9(n)V9(m) COMP-3` | `std.decimal` (prerequisite, see below) |
| file section + open/close | the `with` scope itself — a file lives in its scope and closes when it ends |
| batch program | native binary, no runtime license |

The ownership model is a selling point, not an obstacle: a migrated
batch program cannot leak a handle or double-close a file *by
construction*, which is a claim no incumbent output can make.

## Beachhead (needs Eric's confirmation)

**ANS85 batch COBOL**: files in, files out, ASCII, no CICS, no embedded
SQL, no JCL, no IBM-dialect extensions. This is the NIST suite's home
turf and the classic bank/insurance batch-job class where maintainable
output is easiest to prove and to demo.

**Explicitly deferred, each a later campaign with its own brief:**
CICS transaction programs, `EXEC SQL`, JCL orchestration, EBCDIC data,
IBM Enterprise COBOL dialect, IMS, report writer.

## The honest hard parts

1. **The language is ~20% of the job.** The rest is environment:
   indexed/relative/sequential file organizations with their key and
   status-code semantics, `SORT`/`MERGE`, exact packed-decimal
   arithmetic with COBOL rounding rules (auditors notice a penny),
   edited-`MOVE` formatting (`PIC ZZ9.99-` and friends), intrinsic
   functions. These are runtime prerequisites, not translator features.
2. **Control-flow restructuring has ugly corners.** `PERFORM THRU`
   overlapping ranges, `GO TO` into paragraph ranges, `ALTER`. Most
   real code avoids the worst; where it doesn't, the answer is the loud
   refusal, with relooper-style restructuring added only for shapes the
   census proves common.
3. **`COPY`/`REPLACE`** are textual and must be expanded by our front
   end with source provenance kept, so diagnostics and emitted comments
   point at the copybook, not the expansion.

## Stages

### Stage 0 — census (start here; no ruling needed)

Pull the NIST CCVS COBOL-85 corpus plus a handful of real open batch
programs. Write a With tool (Lexer-style scanner) that counts statement,
clause, and PICTURE-shape frequencies across the corpus. Output: the
funnel — which constructs must translate for which fraction of programs
to convert whole. Every later scope decision cites this census, the way
D32 cited its move-site census. Also fixes the acceptance denominator:
"N of M NIST programs convert-and-pass."

### Stage 1 — runtime prerequisites (std, independent value)

- `std.decimal`: exact fixed-point decimal (digits + scale), COBOL
  rounding modes, sized to `PIC 9(31)` (the i128 work in #914 gives the
  natural limb). Useful far beyond COBOL — money is a first-class
  domain.
- Record-file layer over `std.fs`: sequential/line-sequential first;
  indexed (B-tree keyed, file-status semantics) second.
- Edited formatting: the `PIC` editing mini-language as a formatter.

Each lands with its own tests, independent of the migrator.

### Stage 2 — COBOL front end (FORK: needs Eric's ruling)

Options:
- **A. COBOL checker written in With** (predicted ruling). Lexer,
  fixed/free format handling, `COPY`/`REPLACE` with provenance, parser
  to a semantic model (data division resolved to types/layouts,
  procedure division to a CFG). Same architecture as the compiler's own
  front end; the grammar is shallow (no macros, no types beyond
  PICTURE) — the cost is dialect grind, which the census bounds.
- **B. GnuCOBOL arms-length** as an external parse-dump producer.
  Faster start; GPL coupling, a non-With dependency in a core product
  feature, and the moat outsourced. Against the grain of the
  self-contained doctrine.
- Micro Focus `.int` intermediate code is ruled out: proprietary,
  undocumented, legally radioactive, and post-lowering (the maintainable
  structure is already destroyed in it).

### Stage 3 — the migrator

`with migrate` grows a COBOL front end beside the C one, same spine:
semantic model → idiomatic With emission → loud refusal list. Emission
rules follow the mapping table above; every refusal names program,
paragraph, and clause. Output must compile and pass dual-run — a
migrate fix is done only when the regenerated output does (the
C-migration methodology, unchanged).

### Stage 4 — validation harness

Dual-run driver: original (GnuCOBOL-executed or vendor-executed,
arms-length as a *test oracle* only — an oracle is not a dependency)
vs migrated With binary, same inputs, bit-exact output comparison.
NIST CCVS pass-count is the public metric; golden files checked in;
regressions are red builds.

### Stage 5 — the demo

One real, recognizable batch program (e.g. an interest-calculation or
premium-billing shape) migrated whole: side-by-side source, dual-run
proof, native binary, readable diff. This is the marketing artifact.

## Acceptance

- Census published; scope decisions cite it.
- NIST CCVS: target set in Stage 0; every green program is
  convert-whole + dual-run bit-exact, no per-program patches.
- Zero silent fallbacks in emitted output (audited, not asserted —
  scanner over emitted code for stub markers, same as the C migrator).
- A cold reviewer can read the emitted With for the demo program and
  accept it as human-quality.

## Sequencing note

This is a months-scale flagship campaign. It does not start as a side
effect: current commitments (release burn-down, D33 completion, minicoro
port, build-perf) hold their priority until Eric slots Stage 0, which is
deliberately cheap (a census tool and a corpus pull) and produces the
numbers the go/no-go deserves.
