# Comptime string ordering blocked zlib root generation

The integrated zlib migration translated all 17 upstream programs and
produced byte-identical promoted modules, then failed while sorting the
bundle root's import list: `comparison requires comptime scalar values`.
The reduced program is `const ordered = "alpha" < "beta"`.

LLDB stopped in `ComptimeEvaluator.eval_binary_compare` with `x2=7`
(`BinaryOp.OP_LT`) and both operands' first words equal to 4 (`CV_STR`).
The string branch checked only operations 6 (`!=`) and 5 (`==`), then
the `b.ne` at `0x1000c9a74` went to the rejection block at `0x1000c9b58`.
The call to `ComptimeEvaluator.fail` was at `0x1000c9b7c`; its backtrace
returned to `eval_binary_compare+536`. In the source this is the CV_STR
branch in `src/ComptimeEval.w`, followed by the scalar-only diagnostic.
Transcript: `out/zlib-1103-validation/comptime-string-compare-lldb.log`.

The evaluator omitted all four string ordering operators even though
native codegen's `compare_str_order` already implements them through
`with_str_cmp_ref`. The evaluator now applies those same ordinary string
operators to the stored string values. No migration-specific comparison,
ABI change, or generated-code adjustment is needed.

The regression checks all six relations at compile time and runtime over
equal values, both orderings, empty strings, prefixes, embedded NULs, and
UTF-8. The complete zlib migration also exercises the original sorting
call through the build action's comptime evaluator.
