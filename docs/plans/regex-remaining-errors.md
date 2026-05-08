# Regex Remaining Errors

Generated from `out/tmp/regex-build-errors.txt` after:

```sh
WITH=out/bin/with make regex-build > out/tmp/regex-build-errors.txt 2>&1
```

`regex-build` completed successfully and built:

```text
out/pcre2_build/bin/pcre2test
```

## Summary

There are no remaining `regex-build` errors in this run.

| Category | Count | Notes |
| --- | ---: | --- |
| Codegen errors | 0 | No `error:` diagnostics were emitted. |
| Type mismatches | 0 | No type-mismatch diagnostics were emitted. |
| Moved-value errors | 0 | No moved-value diagnostics were emitted. |
| `&raw const` warnings | 32 | Generated code takes `&raw const` of non-place expressions. These are warnings, not build blockers. |
| Unused generated-label warnings | 880 | Native-goto migration emits labels that can become unreachable after control-flow lowering. These are warnings, not build blockers. |

## Runtime Correctness (regex-test)

Running the upstream PCRE2 RunTest corpus (tests -29 + heap) against the migrated binary:

### Fixed

- **Test 0**: OK (unchecked pcre2test argument tests)
- **Test 1**: OK after PUTCHAR fix — negated single-char class (`[^a]/i`) was compiling to `[^\x00]` because `PUTCHAR(c, code)` macro expansion lost the `*code = c` side-effect in the non-UTF branch. Hand-patched in `out/pcre2_migrated/pcre2_compile.w:19843`.

### Known Remaining Issues

- **Test 3 (locale)**: `pcre2_maketables` doesn't correctly classify high bytes (>127) for locale-specific `\w`, `[[:alpha:]]` etc. Character class bitmaps only include ASCII. Likely a table-generation issue in the migrated `pcre2_chartables` or `pcre2_maketables`.
- **Test 2 (API/errors)**: pcre2test fails on API error tests.
- **Test 4+ (UTF-8)**: Status pending — full verification running.

### Migrator Root Cause

The `PUTCHAR(c, p)` macro expands to `(*p = c, 1)` in non-UTF 8-bit mode — a comma expression that both stores the character and returns 1. The migrator correctly handled the UTF branch (calling `_pcre2_ord2utf_8`) but silently dropped the store side-effect in the else branch, producing just `1` instead of `(*p = c, 1)`.

## Current Status

`regex-build` is no longer blocked by compiler errors. Runtime correctness work is in progress — Test 1 passes after the PUTCHAR fix. Locale handling and UTF-8 tests have remaining issues.
