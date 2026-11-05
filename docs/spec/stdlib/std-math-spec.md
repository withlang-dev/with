# std.math — Design Plan

> **Status (2026-11-01): plan, rewritten 2026-10-11, refreshed to the rulings through D180.** Replaces the
> 2026-07 plan. Follows Eric's direction of 2026-10-10: make NumPy, SciPy and pandas users feel at home, do
> everything those libraries do and more, faster and better, in idiomatic With, by writing very little
> code: curate hardened C libraries, migrate them whole with `with migrate`, and put a With facade on
> top. Nothing here is implemented yet. Items marked **[ruling]** need Eric's decision before code
> follows them. The dataframe library is planned separately (`std-frame-plan.md`).

```
use std.math                // Array, constructors, constants, scalar helpers
use std.math.linalg
use std.math.fft
use std.math.random
use std.math.stats
use std.math.special
use std.math.signal
use std.math.optimize
use std.math.integrate
use std.math.interpolate
use std.math.sparse
use std.math.spatial
use std.math.io
```

`use std.math as np` names the namespace `np` (§18), for anyone who wants `np.zeros(...)`.

---

## Part 1: How std.math is built

### Engines are migrated C corpora; With is the facade

std.math follows the stdlib sourcing rule (D37, `stdlib_sourcing_plan.md`): a library whose
C implementation has stood the test of time is migrated whole with `with migrate`, kept as a corpus (a
`.wo` bundle, D38; migrated against every target and merged, D94; its migrator pinned, D112), and
facaded. The migrator is raw; every With-ism (the `Array` type, ownership, errors, broadcasting, names) is
the facade's. A corpus is an engine under `std.engines.<library>`, named for the library; a facade is
named for its function, and neither maps onto the other (D146).

std.math does **not** link system libraries (Accelerate, OpenBLAS, MKL, vDSP, FFTW) through `c_import`:
a With program depends only on the OS and With's own SDK (D81), and a C wrapper is the path D37 rejected.
An application that wants a vendor BLAS links it itself (`with get`).

A corpus may be part of a larger project, with stand-in headers supplied by its recipe, and its oracle may
be golden values taken from that project's Python test suite (Eric, 2026-10-10). This is what lets
numpy's and scipy's own C serve as engines.

Native With code is written where no acceptable C source exists, and where the algorithm is shorter than
the facade a corpus would need (scalar root finders, simple quadrature rules, 1-D interpolators,
descriptive statistics).

### Engines

| Module | Engine (corpus) | License | Native With on top |
|---|---|---|---|
| `std.math` (Array core) | — | — | storage, strides, broadcasting, elementwise loops, reductions, printing; sort/search from STC's algorithm layer (the stdlib sourcing plan's `std.algorithms`) |
| `linalg` | **BLIS** 2.x, generic configuration (BLAS); **semicolon-lapack** (LAPACK; real routines first) | BSD-3; BSD-3 | `einsum`, matrix functions other than `expm`/`sqrtm`, batching |
| `fft` | **pocketfft C** (`mreineck/pocketfft` C branch) | BSD-3 | n-D, `axes`, `norm`, helpers, plan cache, DCT/DST I–IV (from pocketfft C++'s algorithms) |
| `random` | **numpy `random/src`**: PCG64, PCG64DXSM, Philox, SFC64, MT19937, `distributions.c` | MIT, BSD-3, CC0 | `SeedSequence`, `Rng`, `choice`/`shuffle`/`permutation`/`multivariate_normal` |
| `special` | **Cephes** (scipy 1.13.1's C copy); **AMOS** (scipy's C translation); **Faddeeva** | permission (BSD-3 in scipy); BSD-3/ACM; MIT | complex gamma/digamma/zeta/hyp2f1, Lambert W, Carlson integrals, orthogonal polynomials (ports from scipy's xsf, BSD-3) |
| `stats` | Cephes + **cdflib** (scipy 1.16.3's C) | BSD-3/public domain/ACM | descriptive statistics, quantiles, the distribution objects, a generic PPF, tests; Boost-only distributions as ports |
| `optimize` | **cminpack** (MINPACK); scipy's C `lbfgsb.c`, `tnc.c`, `slsqp.c`; **NLopt** without its LGPL `luksan/` | MINPACK notice; BSD-3/MIT; MIT/BSD-3 | scalar roots, Nelder-Mead/Powell/CG/BFGS, `least_squares`, global optimizers, `curve_fit` glue |
| `integrate` | scipy's C `__quadpack.c`, `lsoda.c`, `dop.c` | BSD-3 | `solve_ivp` steppers (RK23/RK45/DOP853/Radau/BDF), simple rules |
| `interpolate` | scipy's C `dfitpack.c` (FITPACK) | BSD-3 | `interp`, CubicSpline, Akima, PCHIP, B-splines, RBF, grid interpolation |
| `sparse` | **SuperLU** (without `mc64ad.c`), SuiteSparse **AMD/COLAMD**; scipy's C **ARPACK** ("ARNAUD") and **PROPACK** | BSD-3 | CSR/CSC/COO formats and operations, Krylov solvers |
| `spatial` | **Qhull** (needs `setjmp`/`longjmp` support in the migrator) | Qhull license | KD-tree, distance functions |
| `signal` | — (no C source with scipy semantics in f64) | — | filter design and filtering, convolution, windows, spectral analysis, on `fft` |
| `io` | — | — | `.npy`, safetensors, CSV for arrays; `.npz` through `std.zip` (reading exists; writing needs a writer, e.g. miniz) |
| linear programming | **[ruling]** Eric suggested GLPK, which is GPL-3.0-or-later; options are in "Open items" | — | — |

Later, "more than SciPy": SUNDIALS (ODE/DAE, BSD-3), SLEEF (vectorized libm, BSL-1.0), CORE-MATH
(correctly rounded scalar libm, MIT), libsamplerate (BSD-2), QDLDL (sparse LDLᵀ, Apache-2.0).
Image codecs stay out of std ("no ecosystem encroachment", `libstd-spec.md`).

### What the migrator must handle first

Found by a trial migration of pocketfft and by probes (2026-10-11; re-run 2026-11-01 on a release build
of main `a719f858`):

| Construct | Needed by | Today |
|---|---|---|
| C99 libm beyond the D42 table (`fma`, `frexp`, `ldexp`, `fmin`, `fmax`, `nextafter`, …) and `isnan`/`isinf`/`isfinite`/`signbit` | pocketfft, Cephes, LAPACK, nearly all numeric C | refused (#2680) |
| C99 `_Complex` arithmetic, `creal`/`cimag` | LAPACK c/z routines, AMOS, Faddeeva | no type in output, no arithmetic (#2817) |
| `setjmp`/`longjmp` error exits | Qhull | refused (§13.5b) |

A local declared through a pointer typedef and dead code after `return`, both in the 10-11 list, migrate
cleanly now. Migrated pocketfft needs one `-include` shim for `fma` (#2680) and then checks, with no
hand patches; its own test passes for every length 1..8192 with error sums bit-identical to the C build
with the same shim (`4.045940e-12` real, `4.826753e-12` complex).

### Speed

Migration undefines CPU features above the baseline (SSE2/NEON), so each corpus runs its portable C.
That matches NumPy for most of SciPy, where the C is scalar anyway; it does not match NumPy's BLAS.

- **Bundle optimization level [ruling].** `.wo` bundles compile at `-O1` (`build/wo.w:399`), where LLVM does
  not vectorize loops (an `axpy` loop compiles to `mulsd`/`addsd` at `-O1`, `mulpd`/`addpd` at `-O2`).
  Numeric corpora should build at `-O2`.
- **BLAS kernels.** BLIS keeps all speed-critical code in one small gemm micro-kernel per architecture.
  First look for C (intrinsic) kernels BLIS already ships that migrate per target; only then write
  micro-kernels in With's SIMD (D78/D80). Eric: C libraries first.
- **Threads.** Single-threaded at first: std has no thread pool, thread-local storage or lazy global.
  BLIS's thread layer gets a With backend once std has one.

---

## Part 2: The Array type

### One type, a value

```
pub type Array {
    data: Buffer,          // a D120 value buffer: copied with a count, copy-on-write
    dtype: DType,
    shape: [isize; 8],
    strides: [isize; 8],   // in elements
    offset: isize,
    rank: isize,
}
```

One type for scalars (rank 0), vectors, matrices and batches. Shape, strides and offsets are `isize`
(D108/D114). An `Array` has no `Drop` and holds only values, so under D120 it is a value: `let b = a`
copies in O(1), and writing to `b` copies its buffer first. The plan's hand-written `Storage` refcount
is the language's job now. Its copy class is part of its interface (D152): `Array` copies with a count,
as `List` does. It is not an engine-backed collection (the engines compute on its buffer; they don't
hold it), so D152's resource class doesn't apply.

**Shape operations and slicing.** Reshape, transpose and broadcasting return a new `Array` sharing the
buffer, with new shape and strides: O(1) and no copy. Because Arrays are values, a result never writes
through to the array it came from. This is the one deliberate difference from NumPy, where views alias;
it is Swift's model, and With cannot offer aliasing (D120).

Slicing is the language's, not std.math's. D158 rules that strided and multi-dimensional views are a
language feature over `[]T` and `[T; d1, d2, …]` (`tensor[2:5, :, newaxis]`), and that when a numeric
program needs them first, the answer is to schedule the feature rather than add a library spelling.
std.math is that program. **[ruling]** Schedule D158's slicing so that it covers `Array` (a
runtime-shaped value) as well as `[T; d1, d2, …]`. Its value semantics would be the ones above:
`let row = a[0, :]; row[1] = 5.0` changes `row` only, while `a[0, 1] = 5.0` and `a[0, :] = 1.0` change
`a`. Until it lands, `Array` has element access and the shape methods, and no slicing syntax of its own.

### Element types

```
pub enum DType:
    Bool
    I8
    I16
    I32
    I64
    U8
    U16
    U32
    U64
    F32
    F64
    C64     // complex, two f32
    C128    // complex, two f64
```

The element type is a runtime property, as in NumPy: I/O, the dataframe library and mixed-type code need
it, and With has no numeric trait to make `Array[T]` generic code practical (`T: Float` doesn't exist).
Typed access is `a.to_list[f64]()` / `a.item[f64]()`. Complex dtypes need a std `Complex` value type
(none exists outside `c_import`). `f16`/`bf16` wait for With types.

The default element type is `F64` everywhere (NumPy, Julia and R; f32 is opt-in for ML).

Promotion follows NumPy 2 (NEP 50): same type stays; integers widen; int with float gives float; a
literal scalar is *weak*, taking the array's type within its kind (`a_f32 * 2.0` stays `F32`), while a
float literal with an int array gives `F64` (`int_array * 1.5` never truncates), and a literal that
doesn't fit is an error (`u8_array + 1000`); no silent narrowing. `I64` with `U64` has no wider signed
type: `F64`, as NumPy.

**[ruling] Integer division on Arrays.** `/` is true division (an `F64` result) and `%` is floored (the
divisor's sign), as in NumPy, PyTorch, JAX and R; `a.floor_div(b)`, `a.trunc_div(b)` and `a.fmod(b)`
give the others. This departs from With's scalar `/` (truncating) and `%` (the dividend's sign) applied
per element. The alternative is refusing `/` and `%` on integer Arrays; silently truncating would give
Python, R and Julia users wrong numbers.

### Broadcasting

NumPy's rules exactly: shapes right-aligned, size-1 dimensions stretch, missing leading dimensions count
as 1, implemented as stride-0 views. A shape mismatch is a contract violation and panics with both shapes
(`require`, D86): `cannot broadcast shapes [3, 4] and [5]`.

### Errors

Shape and dtype misuse panics (it is a bug, like an index out of range, D27). Numerical failure that a
correct program can meet returns `Result`: `pub error LinalgError = | Singular(isize) | NotPositiveDefinite
| NoConvergence(isize)`, `FftError`, and so on, one error type per module (the D97 shape).

---

## Part 3: The surface

Eric (2026-10-10): "Needs to be Withy, needs to appeal to Python users, ML programmers, Academics. I
recommend looking at julia, R, as well as the popular Python libraries. Within those bounds, it's your
call." The comparison is in with-scratch `std-math/research/array-surface-survey.md`.

### Methods, not free functions

Elementwise math, reductions and shape operations are methods: `a.sqrt()`, `a.exp()`, `a.sum(axis: 0)`,
`a.reshape([3, 4])`, `a.t()`. Three reasons: std's first principle is "methods on types"; a free `sqrt` in
`std.math` would shadow the width-generic scalar builtin wherever `std.math` is imported (§17.6a); and
every public std name joins the unqualified fallback tier (§18, D29), where two std modules exporting
`sum` or `max` are an ambiguity. PyTorch users already write `a.sqrt()`; NumPy users have `a.sum()`.

Free functions are kept for constructors and for operations on several arrays: `zeros`, `ones`, `full`,
`eye`, `arange`, `linspace`, `array`, `concat`, `stack`, `meshgrid`. (`where` is a With keyword;
NumPy's `where(c, x, y)` is `c.select(x, y)`.)

**[ruling] Builtin math names as free calls.** R and Julia users write `sqrt(x)`, NumPy users
`np.exp(-x**2)`. Proposal: a builtin math name called as a free function on a non-float argument calls
that argument's method of the same name (`sqrt(a)` is `a.sqrt()`, `exp(-(x * x))` works), Python's
`abs(x)` → `x.__abs__()` precedent. Nothing in `std.math` then shadows the scalar builtin, and With
already allows both `cos(x)` and `x.cos()` for floats. User functions map with `a.map(f)` and
`a.zip_map(b, f)`.

### Operators

| Source | Meaning |
|---|---|
| `a + b`, `a - b`, `a * b`, `a / b`, `a % b` | elementwise, broadcasting |
| `a @ b` | matrix product (`matmul`) |
| `-a` | elementwise negation |
| `a + 2.0`, `2.0 - a` | scalar broadcast: `a + 2.0` is `Array`'s `add`; `2.0 - a` is `f64`'s, written `extend f64: fn sub(self: &Self, a: &Array) -> Array` (D166, D167) |
| `a < b`, `a == 0.5` | elementwise comparison, a `Bool` array (a mask) **[ruling]** |
| `m & n`, `m \| n`, `m ^ n`, `not m` | mask logic **[ruling]** |
| `m.select(a, b)` | `a` where `m`, else `b` (NumPy's `where(m, a, b)`, R's `ifelse`) |
| `a.array_equal(b)`, `a.allclose(b)`, `a.isclose(b)` | whole-array equality, a `bool`; tolerance checks with NumPy's defaults |

A mask is an `Array` of dtype `Bool`, not a separate type, so `m.sum()` counts and `m.mean()` is a
fraction, as in NumPy, R and Julia. `equal` is not used for whole-array equality because NumPy's
`np.equal` is the elementwise `==`.

**[ruling] Arrays are lane-wise, as SIMD vectors are.** D80 already gives With's SIMD vectors NumPy's
semantics: comparisons are lane-wise and return a mask, a scalar broadcasts on either side of every
lane-wise operator, masks combine with `& | ^` and `not`, `and`/`or` are refused (they short-circuit),
and selection is `m.select(a, b)`. R is the same (`< == & | !` elementwise, `&&`/`||` an error on
vectors); Julia is the outlier (`==` on arrays is one `Bool`, `.==` elementwise).

The scalar on the left needs no ruling any more: an operator is its left operand's method (D166), and a
scalar on the left is the scalar's operator, written as an extension of `f64` (D167). std.math declares
those extensions beside `Array`. The proposal is to let a library type opt into the rest of the
lane-wise rules, in two parts:

1. comparison operators on an opted-in type return its declared mask type, not `bool` (amends D41).
   A boolean test still takes only a `bool` or an integer (D177), never a mask, so `if a == b` is a
   compile error pointing to `array_equal`;
2. user types may define `&`, `|`, `^` and `not` (fixed method names), as masks do.

Without the ruling the fallback is explicit methods: `a.less(b)` style names (not `lt`, which is an
operator override) and NumPy's `m.logical_and(n)`. That works today and reads worse.

Python users will trip on: `~m` is `not m`, and With's `not` binds tighter than `<`, so `not a < b`
means `(not a) < b`; `a < 0.5 & b > 0` needs parentheses (NumPy's docs say so too; R users don't
write them).

`**` doesn't exist in With: `a.pow(2.0)`. Compound assignment desugars to `a = a + b`; in-place updates
are `mut fn` methods (`a.add_in_place(b)`), and a function that updates an array it is given takes it as a
`mut` parameter (`fn normalize(mut a: Array)`, D172).

### Constructors

```
pub fn array[T](data: []T) -> Array                  // 1-D from a slice or List; dtype from T
pub fn zeros(shape: []isize, dtype: DType = .F64) -> Array
pub fn ones(shape: []isize, dtype: DType = .F64) -> Array
pub fn full(shape: []isize, value: f64, dtype: DType = .F64) -> Array
pub fn eye(n: isize, dtype: DType = .F64) -> Array
pub fn arange(start: f64, stop: f64, step: f64 = 1.0, dtype: DType = .F64) -> Array
pub fn linspace(start: f64, stop: f64, num: isize = 50, endpoint: bool = true) -> Array
pub fn logspace(start: f64, stop: f64, num: isize = 50, base: f64 = 10.0) -> Array
impl Array:
    pub fn zeros_like() -> Array
    pub fn reshape(shape: []isize) -> Array
```

No overloading exists (D42), so `array` is generic over the element type (`comptime if T.name() == …`),
and nested data goes through `array_2d(rows: []List[f64])` or flat data plus `reshape`.
`zeros([3, 4])`: brackets make a `List`, which a `[]isize` parameter accepts.

### Elementwise methods

`abs sign sqrt cbrt square exp exp2 expm1 log log2 log10 log1p sin cos tan asin acos atan sinh cosh tanh
floor ceil trunc round clip(lo, hi) pow(x) hypot(b) atan2(b) maximum(b) minimum(b) is_nan is_inf is_finite`
and `astype(dtype)`, `copy()`. Each maps to the width-generic scalar builtins in a loop (or SLEEF later).

### Reductions

```
impl Array:
    pub fn sum(axis: Option[isize] = None, keepdims: bool = false, skip_nan: bool = false) -> Array
    pub fn mean(axis: Option[isize] = None, keepdims: bool = false, skip_nan: bool = false) -> Array
    pub fn variance(axis: Option[isize] = None, ddof: isize = 0, keepdims: bool = false, skip_nan: bool = false) -> Array
    pub fn std(axis: Option[isize] = None, ddof: isize = 0, keepdims: bool = false, skip_nan: bool = false) -> Array
    pub fn item[T]() -> T            // the one element of a size-1 array
    // also: prod min max argmin argmax any all cumsum cumprod median quantile norm
```

`axis:` and `keepdims:` are NumPy's, JAX's, pandas' and the Array API's names (PyTorch's `dim` is the
minority). `axis: None` reduces over everything, `axis: 0` the first axis, `axis: -1` the last (the old
plan's "-1 means all" is dropped). A passed `isize` becomes `Some` (D103). `skip_nan: true` replaces
NumPy's `nan*` family with one flag (R's `na.rm`, pandas' `skipna`). `var` is a keyword, so the method is
`variance`. A reduction returns an `Array` (one method has one return type), a 0-d one when it reduces
everything; `a.sum().item[f64]()` gives the scalar, PyTorch's model. Under the lane-wise rule
`if a.sum() > 0.0:` is a compile error that points to `.item()`. Float sums are pairwise (NumPy's);
small integers sum in `I64`. NaN propagates unless skipped; sorting puts NaN last (as `TotalF64`).

### Indexing

`a[i, j]`, `a[1:4, :]`, `a[::-1]`, `a[..., 0]`, `a[newaxis, :]` and assignment through them use
`MultiIndex`/`MultiIndexMut` (§11.7; `newaxis` is contextual, so no `NEWAXIS` constant). Negative indices
count from the end. A read returns an `Array` (rank 0 for full integer indexing; `.item[f64]()` for the
scalar), and assignment takes an `Array` (a scalar broadcasts through the lane-wise rule, or `full`).
Subscript components must be integers today, so mask and index-array selection use NumPy's own method
names: `a.extract(m)` for `a[m]`, `m.select(0.0, a)` or `a.putmask(m, 0.0)` for `a[m] = 0.0`,
`a.take(idx, axis: 0)` and `a.put(idx, values)` (last write wins), `a.add_at(idx, values)`
(accumulates, `np.add.at`). **[ruling, later]** Mask and index-array subscript components would give
`a[a < 0] = 0`, one of the commonest idioms in NumPy, R, Julia and PyTorch.

Slices are values: after `row = a[0, :]`, `row *= 2.0` leaves `a` unchanged (R's and JAX's semantics;
NumPy and PyTorch users must be told prominently). Negative steps work (`a[::-1]`), unlike PyTorch.

### Shape operations

`reshape transpose permute t squeeze unsqueeze flatten flip broadcast_to` (views); `concat stack split
tile repeat pad roll` (new arrays); properties `shape() rank() size() dtype() is_contiguous()`. Sizes are
`isize`; shapes are `List[isize]`.

### Printing

`print(a)` (`impl Display for Array`) and `f"{a:?}"` (Debug). `f"{a}"` is not available for a struct
today (`print(f"loss = {loss}")` is the first line many Python users write, so that is worth its own
issue), and format specifications reach floats only, so precision is `a.format(precision: 4)`. The
numbers follow NumPy's print options (precision 8, summarize above 1,000 elements with 3 edge items, width
75), so a migrated script's output diffs cleanly against NumPy's; the header shows shape and dtype, as
Julia, PyTorch and JAX do.

```
Array[3, 4] F64
[[ 1  2  3  4]
 [ 5  6  7  8]
 [ 9 10 11 12]]
```

---

## Part 4: Submodules

Signatures follow the same rules (methods where an Array is the subject, `Result` where a correct
program can fail, `isize` sizes, named arguments, enums instead of mode strings).

**`linalg`:** `a @ b`, `a.dot(b)`, `outer`, `kron`, `einsum(spec, operands)`; `det`, `slogdet`,
`inv`, `pinv`, `solve`, `lstsq`, `matrix_rank`, `cond`, `norm`; decompositions `lu`, `qr`, `cholesky`,
`svd`, `eig`, `eigh`, `schur`, `hessenberg`; `expm`, `sqrtm`, `logm`; `solve_sylvester`, Lyapunov,
Riccati. Inputs are copied to column-major contiguous buffers for LAPACK; workspace queries and `info`
codes stay inside; failures are `LinalgError`.

**`fft`:** `fft ifft rfft irfft hfft ihfft fft2 ifft2 fftn ifftn` with `n`, `axis`/`axes`, `norm:
.Backward | .Ortho | .Forward`; `fftfreq rfftfreq fftshift ifftshift next_fast_len`; `dct dst idct idst`
types 1–4. Outputs are `C128` arrays (or `C64`; float32 input is computed in f64 **[decide]**).

**`random`:**
```
pub fn default_rng(seed: u64) -> Rng           // PCG64 seeded through SeedSequence: NumPy's streams
impl Rng:
    pub mut fn random(shape: []isize) -> Array
    pub mut fn normal(shape: []isize, mean: f64 = 0.0, std: f64 = 1.0) -> Array
    pub mut fn integers(low: i64, high: i64, shape: []isize) -> Array
    pub mut fn choice(a: &Array, size: isize, replace: bool = true) -> Array
    pub mut fn permuted(a: &Array, axis: isize = 0) -> Array   // also permutation, spawn
    pub mut fn shuffle(mut a: Array, axis: isize = 0)        // in place, as NumPy's
    // every numpy Generator distribution
```
The generator is a value with `mut fn` methods. A function that draws takes it as `mut rng: Rng` (D172:
any parameter may be `mut`; there is still no `&mut T`), and NumPy's in-place `rng.shuffle(x)` reads the
same, with `x` a mutable place. Module-level conveniences (`random.rand(shape)`) use a process default
generator. Scalar draws stay `std.random`'s (D162: `next[T: Random]()`, `range(lo, hi)`, `seed(u64)`); `std.math.random`
adds NumPy's streams and the array draws, and doesn't replace it.

**`stats`:** descriptive (`median`, `quantile(q, method: .Linear)`, `percentile`, `mode`, `skew`,
`kurtosis`, `cov`, `corrcoef`, `histogram`, `zscore`); distribution values with `pdf cdf sf ppf isf
logpdf rvs mean var interval` for the common continuous and discrete families; tests (`ttest_ind`,
`ks_2samp`, `chi2_contingency`, …).

**`special`:** `gamma lgamma digamma polygamma beta betaln betainc gammainc erf erfc erfinv erfcx
wofz bessel j0 j1 jv y0 y1 yv i0 i1 iv k0 k1 kv airy struve ellipk ellipe zeta expit logit logsumexp
softmax lambertw`: methods on `Array` where one array is the subject (`a.erf()`), functions in
`std.math.special` for several parameters. Scalar `erf`/`erfc`/`tgamma`/`lgamma` are already builtins.

**`signal`:** `butter cheby1 cheby2 ellip bessel firwin remez` (design); `lfilter sosfilt filtfilt
sosfiltfilt`; `convolve correlate fftconvolve oaconvolve` with `mode: .Full | .Same | .Valid`;
`resample resample_poly decimate`; `welch periodogram stft istft spectrogram`; windows; `find_peaks`,
`savgol_filter`, `medfilt`, `hilbert`.

**`optimize`:** `root_scalar` (`brentq`, `bisect`, `newton`), `root`, `least_squares`, `curve_fit`,
`minimize(f, x0, method: .LBFGSB | .NelderMead | .BFGS | …)`, `minimize_scalar`, `differential_evolution`,
`dual_annealing`. Objectives are closures (`fn(&Array) -> f64`, D63). Results are a `MinimizeResult`
value or `Result[_, OptimizeError]`.

**`integrate`:** `quad`, `dblquad`, `nquad`, `trapezoid`, `simpson`, `cumulative_trapezoid`, `solve_ivp(f,
t_span, y0, method: .RK45 | .DOP853 | .Radau | .BDF | .LSODA)`, `odeint`.

**`interpolate`:** `interp`, `make_interp_spline`, `CubicSpline`, `Akima1DInterpolator`, `PchipInterpolator`,
`splrep`/`splev`, `UnivariateSpline`, `RegularGridInterpolator`, `RBFInterpolator`, `griddata` (with
`spatial`).

**`sparse`:** `CsrArray`, `CscArray`, `CooArray` with arithmetic, `@`, slicing and conversion;
`sparse.linalg`: `spsolve`, `splu`, `spilu`, `eigs`, `eigsh`, `svds`, `cg`, `gmres`, `bicgstab`, `minres`,
`lsqr`.

**`spatial`:** `Delaunay`, `ConvexHull`, `Voronoi`, `KDTree`, `distance.cdist`/`pdist`.

**`io`:** `save_npy`/`load_npy`, `save_npz`/`load_npz`, `load_safetensors`/`save_safetensors`, `load_csv`/
`save_csv` for arrays; `from_bytes`/`to_bytes`. Errors are `Result[_, IoError]`.

---

## Part 5: Constants and scalar helpers

`pub const PI`, `E`, `TAU`, `INF`, `NAN` (INF and NAN are new; today's file declares the first three with
`let`). Decimal float literals round correctly since `a5c6f430`, so `TAU == PI + PI`. Today's generic
`abs`/`min`/`max`/`clamp` stay scalar helpers.

---

## Part 6: What std.math is not

Not a GPU library (Crux and Weld are separate). Not an ML framework: no autograd, no modules. Not a
plotting or symbolic library. The dataframe library is its own module (`std-frame-plan.md`).

---

## Part 7: Phases

| Phase | Corpora | Facade | Depends on |
|---|---|---|---|
| 0 | — | — | migrator: C99 libm (#2680); the bundle `-O2`, lane-wise and D158 slicing rulings |
| 1 | pocketfft | `Array` core, constructors, elementwise, reductions, printing; `fft` (1-D) | 0 |
| 2 | numpy `random/src` | `random` | 1 |
| 3 | BLIS, semicolon-lapack (real) | `linalg` (real); `@` | 1 |
| 4 | Cephes, cdflib | `special`, `stats` (real) | 1 |
| 5 | complex: migrator `_Complex` (#2817), then LAPACK c/z, AMOS, Faddeeva | complex dtypes; complex `linalg`/`special` | 3, 4 |
| 6 | scipy C (lbfgsb, tnc, slsqp, quadpack, lsoda, dop, dfitpack), cminpack, NLopt | `optimize`, `integrate`, `interpolate` | 3 |
| 7 | SuperLU, AMD/COLAMD, ARNAUD, PROPACK; Qhull (after `setjmp`) | `sparse`, `spatial` | 3 |
| 8 | — | `signal`, `io`, n-D `fft`, DCT/DST | 1 |

Every corpus brings its upstream tests as an in-tree lane; every facade brings complexity fixtures and
drop-audit cells (sourcing plan, "Facade rules") and golden values from NumPy/SciPy's test suites.

---

## Open items

1. **Linear programming.** Eric suggested GLPK (`ferrandi/glpk`, a mirror of GLPK 5.0), which is
   GPL-3.0-or-later. In std it would make every program using LP a GPL derivative, and a rewrite made
   while reading GLPK is still derived from it, so "reimplement in our own license" works only
   clean-room. Options: clean-room native simplex/interior point; a hand port of HiGHS (MIT, C++, large);
   GLPK as an opt-in package outside std.
2. **[ruling]** Lane-wise operators for Array (and std.frame's `Expr`), Part 3: comparisons return a
   mask (amends D41), and user `& | ^ not`. (A scalar on the left is settled by D166 and D167.)
3. **[ruling]** Builtin math names as free calls dispatch to the argument's method (`sqrt(a)`), Part 3.
4. **[ruling]** Integer `/` and `%` on Arrays: true division and floored remainder, Part 2.
5. **[ruling, later]** Mask and index-array subscripts (`a[a < 0] = 0`), Part 3.
6. **[ruling]** `-O2` for numeric corpus bundles, Part 1.
7. **[decide]** float32 FFT: through f64, or a second engine.
8. A complex scalar type in std (`Complex[T]` or `C64`/`C128` values), needed by FFT output and complex
   dtypes.
9. `f"{x}"` for types with `Display` (today a compile error for any struct; asked separately).
10. **[ruling]** Schedule D158's multi-dimensional slicing to cover `Array`, Part 2.
