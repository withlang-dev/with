# Private token-paste dependencies (#1102)

The first macro-origin batch, `0fe0b3aa`, passed the full build, fixpoint,
988 behavior tests, and a compiler audit (2,507,795 facts, zero violations).
Its full battery failed in `c-migrator-core-tests` at
`paste_suffix_intmax_max_literal`; it is not a green batch.

That check requires public declarations for SDK-owned `INTMAX_MAX`,
`UINTMAX_MAX`, `INTMAX_MIN`, and `INTMAX_C`. Those expectations conflict
with #1102's requested origin filtering. A maintainer question is pending
before changing them: use project-owned aliases, assert SDK names are absent,
and retain the token-pasting and execution checks. The original check has
not been weakened or bypassed.

The same fixture exposed a separate compiler regression. Its project macro
`X_SHL(n)` depends on SDK `INTMAX_C(1)`. In the first origin patch,
`ci_expand_private_macro_body` rejected every replacement containing `#`,
including the supported `(v ## L)` integer-suffix pattern.

LLDB stopped in the actual failing stage2 at `with_str_contains_ref`, called
from `ci_expand_private_macro_body+744`. The replacement was `(v ## L)`;
the predicate returned `w0=1` at PC 0x10038fe58, and `cbnz w21` at +768
took the empty-result branch. The caller received an empty string for
`(INTMAX_C(1) << (n))` at `ci_translate_macros+6824`, PC 0x10025334c.
Logs: `/tmp/with-macro-paste-branch-lldb.txt` and
`/tmp/with-macro-paste-lldb.txt`.

A raw-preprocessing-token trial exposed why the existing typed-literal
translator must own this operation. Expanding to `1L` entered
`ci_strip_int_suffix`; LLDB observed it return `"1"` to
`ci_parse_postfix_expr+660`, PC 0x100621dac in that dev compiler.
`/tmp/with-macro-paste-width-lldb.txt` records the call. The established
`ci_paste_int_literal` path instead produces `1i64` and handles combined
unsigned suffixes.

The fix retains a supported private paste call until the expression parser
folds it through `ci_paste_int_literal`. No SDK helper declaration is needed.
Private wrapper chains still expand before expression parsing, preserving C
precedence. The original fixture again preserves the i64 literal.

Executing the public helper exposed two further errors in macro expression
translation. LLDB observed `ci_parse_shift_expr` return `(1i64 << n)` to
`ci_parse_rel_expr+1080` (PC 0x1006a6634), and
`ci_infer_macro_return_type_from_expr` return `T` for that expression to
`ci_translate_macros+7012` (PC 0x1001be920). The former violates With's
unsigned shift-count rule; the latter incorrectly makes the result depend
on the count type. Logs: `/tmp/with-macro-paste-shift-lldb.txt` and
`/tmp/with-macro-paste-return-lldb.txt`. Shift translation now supplies an
unsigned count where needed, and result inference follows the left operand,
including typed pasted literals. The resulting helper returns i64 and
uses `(1i64 << (n as u32))`.

`behav_migrate_private_token_paste.w` covers a private wrapper chain, an
unsigned pasted literal shifted to bit 63, a project-owned callable alias,
and execution of the generated project macros while SDK names remain absent.
All three targeted tests passed with the updated stage2:
`behav_migrate_private_token_paste`, `behav_migrate_macro_origins`, and
`behav_c_import_macros_no_cc` (`/tmp/with-macro-shift-final-tests.log`).
Both corpora were regenerated with that stage2: PCRE2 completed 33/33 files
and zlib completed 15 files plus two harnesses. Every generated library file
matches this branch byte for byte (the separately generated PCRE2 `bundle.w`
is outside migration output). Logs: `/tmp/with-macro-shift-pcre2-migrate.log`
and `/tmp/with-macro-shift-zlib-migrate.log`.

A scratch copy of the original core fixture with project-owned aliases for
the four SDK macros migrates and executes successfully, retaining its entire
C runtime check (`/tmp/with-sdk-expectations-proposal-run.log`). The final
battery remains pending the maintainer's ruling on the conflicting SDK-export
assertions.
