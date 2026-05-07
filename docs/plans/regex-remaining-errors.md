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

## Current Status

`regex-build` is no longer blocked by compiler errors. The next regex work should focus on runtime correctness under `regex-test`, not on build failures.
