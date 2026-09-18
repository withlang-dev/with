# Primary verification — `lib/std/traits.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 303 lines (two complete reads)

## Scope examined

Trait declarations (Eq/Ord/Add/Sub/Mul/Div/MatMul/Neg/Try/Deref/
Hash/Debug/Display/Error/Default/Clone/Drop/Iter/Contains/
Scoped/ScopedMut/MultiIndex(+Mut)/IndexGet/IndexPlace) plus
primitive impls (Eq/Ord/Default/Clone/Debug/Hash for
i8-i64/u8-u64/f32-f64/bool/str), `ControlFlow`, and the
PK_INDEX hardcoded-projection note (`:299-303`).

## Behavioral matrix (all EXECUTED)

- `docs/audit/probes/traits/main.w`, 15/15 PASS:
  str FNV-1a `hash_value` ("hello", "") == independent python
  oracle exactly; str `cmp` orderings ("b"/"a", "abc"/"abd",
  prefix "abc"/"ab" → 1); bool `cmp`; `i32`/`bool` defaults;
  i32 `clone`; `debug_str` for i32/bool/str (quoted `"hi"`).
- Probe-authoring notes: `7.method()` fails to lex (`7.` scans
  as float — bind a var first); `print` takes `&str` only.

## Findings

None. Review notes (not defects): signed-`>>` in user xorshift
style code is the author's choice (cf. random.w oracle note);
`IndexPlace` contract explicitly implementation-defined.

Verdict: COMPLETE
