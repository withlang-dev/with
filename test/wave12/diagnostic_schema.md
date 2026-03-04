# Wave 12 Diagnostic Comparison Schema

## Purpose

Defines the normalized comparison format for compiler diagnostics emitted by
Stage2 and Stage3 during fixpoint validation.

## Diagnostic Fields

| Field      | Description                                      |
|------------|--------------------------------------------------|
| severity   | `error` or `warning`                             |
| code/class | Classified diagnostic category (see below)       |
| span       | Normalized source location (basename only)       |
| message    | Raw diagnostic text (used for class extraction)  |

## Normalization Rules

1. **Path stripping**: Replace absolute file paths with basename only.
   `/Users/foo/project/test/wave10/cases/llvm_minimal.w` → `llvm_minimal.w`

2. **Column stripping**: Remove column numbers from span references.
   `file.w:10:5` → `file.w:10`

3. **Whitespace normalization**: Collapse runs of whitespace to single space,
   trim leading/trailing whitespace from each line.

4. **Case normalization**: Lowercase all text before class extraction.

## Diagnostic Classes

Diagnostics are classified into semantic categories to avoid brittleness from
textual differences between compiler stages:

- `parse_expected_expression` — parser expected-expression errors
- `type_mismatch` — type mismatch or wrong argument type
- `generic_type_error` — unknown type or inference failure
- `missing_trait_impl` — does not implement trait
- `object_safety` — object-safety violations
- `unsupported_call` — unsupported call expressions
- `unsized_type` — cannot allocate unsized type
- `codegen_failed` — code generation failures
- `build_failed` — build failures
- `link_failed` — linking failures

Unclassified diagnostics fall through to their lowercased text.

## Tri-State Result Policy

Each corpus entry produces one of three results:

| Result              | Meaning                                            |
|---------------------|----------------------------------------------------|
| `PASS`              | Stage2 and Stage3 produce structurally equivalent output |
| `FAIL`              | Outputs differ beyond normalization                 |
| `KNOWN_DIVERGENCE`  | Declared divergence, tracked in corpus file         |

## Comparison Strategy

- **IR mode**: Full structural comparison after LLVM metadata normalization.
- **Check mode**: Compare diagnostic class and severity only (not exact text).
- **Build mode**: Compare exit codes and diagnostic class on failure.
- **Run mode**: Compare exit codes, stdout, and stderr verbatim.
