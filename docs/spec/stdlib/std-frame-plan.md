# std.frame — Dataframe Plan (draft)

> **Status (2026-10-11, refreshed 2026-11-01 to the rulings through D180): proposal.** Eric, 2026-10-10:
> "we will definitely need a pandas-like library", appealing to Python users, ML programmers and academics, after looking at Julia, R and the Python
> libraries. Companion to `std-math-spec.md`. The survey behind it is with-scratch
> `std-math/research/dataframe-survey*.md`. Items marked **[ruling]** need Eric.

## What the survey says

pandas, Polars, R (base, dplyr, data.table) and Julia (DataFrames.jl) have converged, mostly away from
pandas' original design:

- **No row index.** Polars and DataFrames.jl have none, tibbles drop row names, and pandas' index
  alignment (arithmetic silently producing the union of labels with NaN) is its most cited surprise.
- **One missing value for every type.** Polars `null` (a validity bitmap; NaN is a float, not missing),
  Julia `missing`, R `NA`; pandas 3.0 converges on `NA`. pandas' four markers that compare differently
  are a standing complaint.
- **No ambiguous views.** pandas 3.0 made copy-on-write the only mode; Julia makes aliasing explicit.
- **Arrow memory, strict types.** Polars is Arrow-native and refuses lossy casts; pandas 3.0 bans
  silent upcasting on assignment.
- **Expressions over columns.** Polars `pl.col("a") * 2`, pandas 3.0 `pd.col`, dplyr's bare names,
  Julia's `:a => f => :b` and its macro layers. The verb names are close across all of them.

std.frame starts where they ended up, not where pandas started.

## Data model

```
pub type DataFrame { columns: List[Column], names: List[str] }   // a value (D120)
pub type Column { dtype: ColType, data: Buffer, validity: Buffer, len: isize }
```

- **No row index.** Rows are positions. A key is an ordinary column; lookups are `filter` or `join`.
- **Arrow layout.** Columns follow the Arrow columnar format (nanoarrow, Apache-2.0, as the layout and
  interchange engine), so Parquet/Feather/IPC read and write without conversion and other Arrow tools
  can share data.
- **Missing values are `null`,** one validity bit per row, for every type. Element access gives
  `Option[T]` (`col.get[f64](i)`). NaN is a float value, not missing (as Polars and IEEE).
  Aggregations skip nulls; arithmetic propagates them; `fill_null`, `drop_nulls`, `is_null`.
- **Values, not views.** A `DataFrame` and its `Column`s are D120 values: `let b = df` is O(1), and every
  verb returns a new frame sharing unchanged columns. There is no chained-assignment trap to warn about.
  Their copy class is part of their interface (D152): both copy with a count, as `List` does; nanoarrow
  serves the layout and interchange and doesn't hold a frame, so D152's resource class doesn't apply.
- **Column types:** `Bool`, `I8`…`I64`, `U8`…`U64`, `F32`, `F64`, `Str`, `Decimal` (std.decimal, D123),
  `Date`, `Time`, `DateTime`, `Duration` (std.time, D123; time zones later, as D123 says), `Categorical`
  (fixed categories, Polars' `Enum`). Nested `List`/`Struct` later. Casts are strict: a lossy cast is
  an error unless asked for (`cast(.F32, strict: false)` gives null).
- **Null in a condition.** `filter` drops rows whose condition is null (dplyr's and SQL's behavior);
  comparisons with null are null, and `&`/`|` follow three-valued logic (R, Julia, pandas `NA`).
- **Order is predictable.** `group_by` keeps first-appearance order and joins keep the left frame's
  order by default (pandas' and dplyr's behavior; Polars 2.0 and DataFrames.jl leave it undefined for
  speed, which surprises people). Sorting is stable.

## Expressions

The verbs take expressions over columns:

```
use std.frame.{col, lit}

let adults = people
    .filter(col("age") >= 18)
    .with_columns([(col("weight") / (col("height") * col("height"))).alias("bmi")])
    .group_by(["city"])
    .agg([count().alias("n"), col("bmi").mean().alias("mean_bmi")])
    .sort("mean_bmi", descending: true)
```

Output names come from `.alias(name)` (Polars' spelling): With's named arguments name declared
parameters, so there is no `**kwargs` form like pandas' `assign(bmi=...)`.

An `Expr` is a value describing a column computation (Polars' model; pandas 3.0's `pd.col`). It needs:

- arithmetic between expressions (`col("a") / col("b")`): fixed operator methods, available today;
- a scalar on either side (`col("a") * 2`, `1 - col("p")`): settled. An operator is its left operand's
  method (D166), and a scalar on the left is the scalar's, written as an extension (`extend i64:` and
  `extend f64:`, D167), which std.frame declares beside `Expr`;
- comparisons producing an expression (`col("age") >= 18`): **[ruling]**, same as above, amending D41
  for lane-wise types;
- `&`, `|`, `not` on boolean expressions: **[ruling]**, same.

Without the ruling the spelling is method calls (`col("age").ge(lit(18))`), which works today and reads
like Polars' method forms. Row closures (`df.filter(r => r.f64("age") >= 18.0)`) are possible with
D63 callables but run per row and lose the column engine; they stay an escape hatch, as pandas'
`apply` is.

With's planned `from` query expressions (`docs/proposals/from-query-expressions.md`) are a natural
second front end: `from people | where .age >= 18 | group_by(.city) | ...` would lower to the same
expressions.

## The v1 verb set

| Verb | std.frame | pandas | Polars | dplyr | DataFrames.jl |
|---|---|---|---|---|---|
| choose columns | `select(...)` | `df[[…]]` | `select` | `select` | `select` |
| choose rows | `filter(expr)` | `df[mask]`, `query` | `filter` | `filter` | `subset` |
| add/replace columns | `with_columns([expr.alias(name)])` | `assign` | `with_columns` | `mutate` | `transform` |
| order rows | `sort(by, descending:)` | `sort_values` | `sort` | `arrange` | `sort` |
| group and summarize | `group_by(keys).agg([expr.alias(name)])` | `groupby().agg` | `group_by().agg` | `group_by \|> summarise` | `combine(groupby())` |
| per-group columns | `with_columns([expr.over(keys)])` | `groupby().transform` | `.over()` | `group_by \|> mutate` | `transform(groupby())` |
| join | `join(other, on:, how: .Inner \| .Left \| .Right \| .Full \| .Semi \| .Anti)` | `merge` | `join` | `*_join` | `*join` |
| stack frames | `concat(frames)` | `concat` | `concat` | `bind_rows` | `vcat` |
| wide/long | `pivot(on:, index:, values:, agg:)`, `unpivot(index:)` | `pivot_table`, `melt` | `pivot`, `unpivot` | `pivot_wider`, `pivot_longer` | `unstack`, `stack` |
| windows | `expr.shift(n)`, `.rank()`, `.cum_sum()`, `.rolling_mean(n)` | `shift`, `rolling` | same | `lag`, `cumsum` | packages |
| distinct, counts | `unique(subset:)`, `value_counts(col)`, `describe()` | same | same | `distinct`, `count` | `unique`, `describe` |
| missing | `drop_nulls()`, `fill_null(value)` | `dropna`, `fillna` | same | `drop_na`, `replace_na` | `dropmissing` |
| peek | `head(n)`, `tail(n)`, `shape()`, `schema()`, `print(df)` | same | same | `head`, `glimpse` | `first`, `describe` |

One spelling per operation (no aliases). The names follow Polars where the five libraries differ,
because Polars has the same no-index, null, expression model; `group_by`, `filter`, `select` and
`join` are also dplyr's or close to it. `select` and `where` are reserved words in With; `select` works
as a method name (D80's `m.select(a, b)`), so the verbs are methods (`df.select(...)`), never free
functions.

**CSV inference** follows the safer of the four: readr samples values spread across the whole file (not
the first rows), data.table's `fread` re-reads a column that needs a wider type, and Polars raises with
the fix in the message. std.frame samples across the file and, when a later value doesn't fit, widens the
column (int to float, anything to string) and reports it, never producing a silent mixed column.

**I/O v1:** `read_csv`/`write_csv` (pandas' C tokenizer as the engine, with Polars-style inference: a
sample of rows, then an error naming the row and the fix, never a silent object column),
`read_parquet`/`write_parquet` (native, on nanoarrow and migrated zstd/lz4/snappy), Arrow IPC/Feather,
`read_json` (newline-delimited). Conversions: a numeric column to and from a `std.math` `Array`
(`df.to_array(["x", "y"])` for model input), and `from_rows`/`to_rows` for small data.

**Later:** lazy plans with an optimizer (Polars' `scan_*`/`collect`), time-based grouping and resampling
(`group_by_dynamic`, needs time zones), nested types, Excel/SAS/Stata readers, SQL (`std.sqlite`),
multi-threaded execution (when std has a pool).

## Engines

| Need | Engine | Native |
|---|---|---|
| column layout, IPC | nanoarrow (Apache-2.0) | the Column/DataFrame types |
| hashing for group_by, join, unique | STC `hmap` (the default `HashMap` engine already selected) | the hash kernels over columns |
| sort | STC algorithm layer; a stable sort | multi-key comparator |
| strings | PCRE2 (have), utf8proc (on the old stdlib list) | `str` namespace methods |
| dates | std.time (D123); timelib, c-dt for parsing and business days | `dt` namespace methods |
| CSV | pandas `tokenizer.c` (BSD-3, shim header) | type inference, null markers |
| Parquet | zstd, lz4, brotli (migrated), snappy (native) | the Parquet reader/writer |

Most of std.frame is native With, as the survey found: C supplies the substrate (roughly a quarter of the
work), and the dataframe semantics have no permissive C engine to migrate (DuckDB is C++, Polars Rust,
MonetDB and data.table MPL).

## Open items

1. **[ruling]** Lane-wise operators for `Expr` (the same ruling as for `Array`): comparisons and `& | not`.
2. Module name: `std.frame` (proposed) vs `std.data` vs `std.df`.
3. Group/join order: predictable by default (proposed) vs undefined for speed with `maintain_order`.
4. Null join keys: match each other (dplyr's default, `na_matches = "na"`) or not (Polars `nulls_equal=False`,
   SQL). Proposed: not, with `nulls_equal: true` available.
5. Whether the `from` query syntax is the primary front end or a second one. Its `.age` column marks
   avoid dplyr's most cited problem (bare column names break inside user functions).
