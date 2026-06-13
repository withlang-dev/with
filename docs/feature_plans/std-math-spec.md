# std.math — Design Specification

**The standard numerical computing library for With.**

Pure CPU. No external dependencies. Part of the standard library.

```
use std.math
use std.math.linalg
use std.math.random
use std.math.stats
use std.math.fft
use std.math.signal
use std.math.interpolate
use std.math.optimize
use std.math.integrate
use std.math.special
use std.math.io
```

**Design priorities:**
1. Ergonomic — feels like a native language feature, not a library
2. Familiar — Python/NumPy/SciPy vocabulary and semantics
3. Efficient — LLVM-optimized CPU code, vendor BLAS/LAPACK for
   linear algebra, no hidden copies
4. Comprehensive — scientists should not miss Python

**Architecture:**

std.math is a CPU library. It does not know what a GPU is.
Memory is heap-allocated via With's allocator. Compute is
LLVM-compiled With code. Linear algebra and FFT call vendor-
optimized libraries (Accelerate, OpenBLAS, vDSP, FFTW) via
`c_import`. This is the same architecture as NumPy.

GPU-accelerated math is a separate concern handled by non-standard
libraries (Crux, Weld) that may wrap or interoperate with
std.math types.

---

## Part 1: The Core Type

### Array

```
@[drop]
type Array = {
    storage: *mut Storage,
    view: View,
}
```

One type. Not Tensor, not NDArray, not Matrix, not Vector. Every
numerical object in std.math is an Array. A 0-dim Array is a
scalar. A 1-dim Array is a vector. A 2-dim Array is a matrix. A
4-dim Array is a batch of images. Same type, same operations,
same rules.

### View

```
type View = {
    offset: usize,          // byte offset into storage
    shape: Shape,
    strides: Strides,
    dtype: DType,
}

type Shape = {
    dims: [i64; 8],
    rank: i32,
}

type Strides = {
    elems: [i64; 8],        // byte strides
    rank: i32,
}
```

Views are value types. Creating, reshaping, or transposing a view
is pure arithmetic — no allocation, no memory access.

### Storage

```
type Storage = {
    ptr: *mut u8,
    size: usize,
    refcount: i32,
}

fn storage_new(size: usize) -> *mut Storage
fn storage_retain(s: *mut Storage)
fn storage_release(s: *mut Storage)  // free at refcount 0
```

Storage is a heap allocation. `storage_new` calls the allocator.
`storage_release` decrements refcount and frees at zero. No
devices, no streams, no GPU handles.

### Ownership model

**All inputs are borrowed.** Every function that receives an Array
takes `&Array`. The function reads but does not consume. The caller
retains ownership.

**All outputs are owned.** Every function that produces an Array
returns `Array` (owned). New Storage with refcount = 1.

**View ops share Storage.** `reshape`, `transpose`, `slice` return
an owned Array pointing to the same Storage (refcount++). No copy.

**Auto-referencing makes `&` invisible.** The user writes
`add(a, b)`. The compiler sees `add(&a, &b)`.

**Drop is automatic.** When an Array goes out of scope, `Drop`
decrements the Storage refcount. At 0, memory is freed.

```
// What the user writes:
let c = a + b           // borrows a and b, c is new
let d = a + c           // a reused (still borrowed)
// c dropped at scope exit — memory freed

// What the compiler sees:
let c = Add.add(&a, &b)
let d = Add.add(&a, &c)
```

No leaks. No clones. No manual cleanup. No `&` in user code.

---

## Part 2: Constructors

### From data

```
fn array(data: &[f32]) -> Array
fn array(data: &[f64]) -> Array
fn array(data: &[i32]) -> Array
fn array(data: &[i64]) -> Array
fn array_2d(data: &[&[f32]]) -> Array     // [[1,2],[3,4]] → 2D
fn array_nd(data: &[u8], shape: Shape, dtype: DType) -> Array

fn from_ptr(ptr: *const u8, shape: Shape, dtype: DType) -> Array
```

`array` infers shape from data length. `array_2d` for nested
slices. `from_ptr` wraps external memory — Storage is marked
borrowed, `free` is a no-op.

### Filled

```
fn zeros(shape: Shape, dtype: DType = Float32) -> Array
fn ones(shape: Shape, dtype: DType = Float32) -> Array
fn full(shape: Shape, value: f64, dtype: DType = Float32) -> Array
fn zeros_like(a: &Array) -> Array
fn ones_like(a: &Array) -> Array
fn full_like(a: &Array, value: f64) -> Array
fn eye(n: i32, dtype: DType = Float32) -> Array
fn diag(a: &Array) -> Array
fn empty(shape: Shape, dtype: DType = Float32) -> Array
```

### Sequences

```
fn arange(start: f64, stop: f64, step: f64 = 1.0,
          dtype: DType = Float64) -> Array
fn linspace(start: f64, stop: f64, num: i32,
            dtype: DType = Float64) -> Array
fn logspace(start: f64, stop: f64, num: i32,
            base: f64 = 10.0, dtype: DType = Float64) -> Array
fn geomspace(start: f64, stop: f64, num: i32,
             dtype: DType = Float64) -> Array
```

### From ranges

```
fn array(range: Range[i32]) -> Array
fn array(range: Range[f64], step: f64) -> Array
```

---

## Part 3: Elementwise Operations

All take `&Array`, return owned `Array`. Auto-ref makes `&`
invisible.

### Unary

```
fn neg(a: &Array) -> Array
fn abs(a: &Array) -> Array
fn sign(a: &Array) -> Array
fn exp(a: &Array) -> Array
fn exp2(a: &Array) -> Array
fn log(a: &Array) -> Array
fn log2(a: &Array) -> Array
fn log10(a: &Array) -> Array
fn log1p(a: &Array) -> Array
fn sqrt(a: &Array) -> Array
fn rsqrt(a: &Array) -> Array
fn square(a: &Array) -> Array
fn cbrt(a: &Array) -> Array
fn ceil(a: &Array) -> Array
fn floor(a: &Array) -> Array
fn round(a: &Array) -> Array
fn trunc(a: &Array) -> Array
fn sin(a: &Array) -> Array
fn cos(a: &Array) -> Array
fn tan(a: &Array) -> Array
fn asin(a: &Array) -> Array
fn acos(a: &Array) -> Array
fn atan(a: &Array) -> Array
fn sinh(a: &Array) -> Array
fn cosh(a: &Array) -> Array
fn tanh(a: &Array) -> Array
fn sigmoid(a: &Array) -> Array
fn reciprocal(a: &Array) -> Array
fn logical_not(a: &Array) -> Array
fn bitwise_not(a: &Array) -> Array
fn isnan(a: &Array) -> Array
fn isinf(a: &Array) -> Array
fn isfinite(a: &Array) -> Array
```

### Binary

```
fn add(a: &Array, b: &Array) -> Array
fn sub(a: &Array, b: &Array) -> Array
fn mul(a: &Array, b: &Array) -> Array
fn div(a: &Array, b: &Array) -> Array
fn floordiv(a: &Array, b: &Array) -> Array
fn mod_(a: &Array, b: &Array) -> Array
fn pow(a: &Array, b: &Array) -> Array
fn maximum(a: &Array, b: &Array) -> Array
fn minimum(a: &Array, b: &Array) -> Array
fn atan2(a: &Array, b: &Array) -> Array
fn hypot(a: &Array, b: &Array) -> Array
fn logical_and(a: &Array, b: &Array) -> Array
fn logical_or(a: &Array, b: &Array) -> Array
fn logical_xor(a: &Array, b: &Array) -> Array
fn bitwise_and(a: &Array, b: &Array) -> Array
fn bitwise_or(a: &Array, b: &Array) -> Array
fn bitwise_xor(a: &Array, b: &Array) -> Array
fn left_shift(a: &Array, b: &Array) -> Array
fn right_shift(a: &Array, b: &Array) -> Array
```

### Ternary

```
fn where_(cond: &Array, a: &Array, b: &Array) -> Array
fn clamp(a: &Array, lo: f64, hi: f64) -> Array
fn lerp(a: &Array, b: &Array, t: f64) -> Array
```

### Operators

```
impl Add for Array:     fn add(self: &Self, rhs: &Array) -> Array
impl Sub for Array:     fn sub(self: &Self, rhs: &Array) -> Array
impl Mul for Array:     fn mul(self: &Self, rhs: &Array) -> Array
impl Div for Array:     fn div(self: &Self, rhs: &Array) -> Array
impl Neg for Array:     fn neg(self: &Self) -> Array
impl MatMul for Array:  fn matmul(self: &Self, rhs: &Array) -> Array

// Scalar interop (both directions via multi-param dispatch F8):
impl Add for (Array, f64)   impl Add for (f64, Array)
impl Sub for (Array, f64)   impl Sub for (f64, Array)
impl Mul for (Array, f64)   impl Mul for (f64, Array)
impl Div for (Array, f64)   impl Div for (f64, Array)
impl Pow for (Array, f64)   impl Pow for (f64, Array)
impl Pow for (Array, i32)
// Same for i32, i64, f32 on both sides

// Compound assignment (in-place if sole owner, COW if shared):
impl AddAssign for Array
impl SubAssign for Array
impl MulAssign for Array
impl DivAssign for Array
```

### Comparisons (return boolean Arrays)

```
impl Eq for (Array, Array):  fn eq(self, rhs) -> Array
impl Lt for (Array, Array):  fn lt(self, rhs) -> Array
impl Gt for (Array, Array):  fn gt(self, rhs) -> Array
impl Le for (Array, Array):  fn le(self, rhs) -> Array
impl Ge for (Array, Array):  fn ge(self, rhs) -> Array
impl Ne for (Array, Array):  fn ne(self, rhs) -> Array

// Scalar comparisons (both directions):
impl Eq for (Array, f64)     impl Eq for (f64, Array)
impl Lt for (Array, f64)     impl Lt for (f64, Array)
// etc.
```

`a == b` on two Arrays returns a boolean Array, not a `bool`. For
scalar equality: `equal(a, b)` returns `bool`, or `all(a == b)`.

---

## Part 4: Reductions

```
fn sum(a: &Array, dim: i32 = -1, keepdim: bool = false) -> Array
fn prod(a: &Array, dim: i32 = -1, keepdim: bool = false) -> Array
fn mean(a: &Array, dim: i32 = -1, keepdim: bool = false) -> Array
fn var_(a: &Array, dim: i32 = -1, keepdim: bool = false, ddof: i32 = 0) -> Array
fn std_(a: &Array, dim: i32 = -1, keepdim: bool = false, ddof: i32 = 0) -> Array
fn max(a: &Array, dim: i32 = -1, keepdim: bool = false) -> Array
fn min(a: &Array, dim: i32 = -1, keepdim: bool = false) -> Array
fn argmax(a: &Array, dim: i32 = -1) -> Array
fn argmin(a: &Array, dim: i32 = -1) -> Array
fn any(a: &Array, dim: i32 = -1) -> Array
fn all(a: &Array, dim: i32 = -1) -> Array
fn cumsum(a: &Array, dim: i32 = -1) -> Array
fn cumprod(a: &Array, dim: i32 = -1) -> Array
fn norm(a: &Array, ord: f64 = 2.0, dim: i32 = -1, keepdim: bool = false) -> Array
```

`dim = -1` means reduce over all dimensions (return scalar Array).
Named arguments make these readable: `sum(a, dim: 0, keepdim: true)`.

### NaN-aware variants

```
fn nansum(a: &Array, dim: i32 = -1, keepdim: bool = false) -> Array
fn nanmean(a: &Array, dim: i32 = -1, keepdim: bool = false) -> Array
fn nanstd(a: &Array, dim: i32 = -1, keepdim: bool = false) -> Array
fn nanmax(a: &Array, dim: i32 = -1, keepdim: bool = false) -> Array
fn nanmin(a: &Array, dim: i32 = -1, keepdim: bool = false) -> Array
```

### NaN policy

1. Arithmetic propagates NaN. IEEE 754.
2. Comparisons with NaN return false. IEEE 754.
3. Standard reductions propagate NaN. `nan*` variants skip NaN.
4. Sorting puts NaN at the end.

---

## Part 5: Shape Operations

### Zero-cost view ops (share Storage, no copy)

```
fn reshape(a: &Array, shape: Shape) -> Array
fn transpose(a: &Array, dim0: i32 = 0, dim1: i32 = 1) -> Array
fn permute(a: &Array, order: &[i32]) -> Array
fn expand(a: &Array, shape: Shape) -> Array
fn squeeze(a: &Array, dim: i32 = -1) -> Array
fn unsqueeze(a: &Array, dim: i32) -> Array
fn flatten(a: &Array, start: i32 = 0, end: i32 = -1) -> Array
fn slice(a: &Array, dim: i32, start: i32, end: i32) -> Array
fn narrow(a: &Array, dim: i32, start: i32, length: i32) -> Array
fn flip(a: &Array, dim: i32) -> Array
fn t(a: &Array) -> Array
```

These return owned Arrays sharing Storage (refcount++). Pure
metadata — no allocation, no memcpy.

`reshape` may require a copy if strides are incompatible. In
that case it silently allocates and copies.

### Ops requiring allocation

```
fn contiguous(a: &Array) -> Array
fn clone(a: &Array) -> Array
fn cat(arrays: &[&Array], dim: i32 = 0) -> Array
fn stack(arrays: &[&Array], dim: i32 = 0) -> Array
fn split(a: &Array, sections: i32, dim: i32 = 0) -> Vec[Array]
fn chunk(a: &Array, chunks: i32, dim: i32 = 0) -> Vec[Array]
fn gather(a: &Array, dim: i32, index: &Array) -> Array
fn scatter(a: &Array, dim: i32, index: &Array, src: &Array) -> Array
fn index_select(a: &Array, dim: i32, index: &Array) -> Array
fn repeat(a: &Array, repeats: &[i32]) -> Array
fn tile(a: &Array, reps: &[i32]) -> Array
fn pad(a: &Array, padding: &[(i32, i32)], value: f64 = 0.0) -> Array
fn roll(a: &Array, shift: i32, dim: i32 = 0) -> Array
fn rot90(a: &Array, k: i32 = 1, dims: (i32, i32) = (0, 1)) -> Array
```

### Properties

```
fn shape(a: &Array) -> Shape
fn dtype(a: &Array) -> DType
fn ndim(a: &Array) -> i32
fn numel(a: &Array) -> i64
fn is_contiguous(a: &Array) -> bool
fn nbytes(a: &Array) -> i64
fn item(a: &Array) -> f64
fn item_i64(a: &Array) -> i64
```

---

## Part 6: Matrix Operations

```
fn matmul(a: &Array, b: &Array) -> Array
fn dot(a: &Array, b: &Array) -> Array
fn inner(a: &Array, b: &Array) -> Array
fn outer(a: &Array, b: &Array) -> Array
fn tensordot(a: &Array, b: &Array, dims: i32) -> Array
fn einsum(subscripts: str, arrays: &[&Array]) -> Array
fn bmm(a: &Array, b: &Array) -> Array
fn mv(a: &Array, b: &Array) -> Array
fn mm(a: &Array, b: &Array) -> Array
fn kron(a: &Array, b: &Array) -> Array
fn cross(a: &Array, b: &Array, dim: i32 = -1) -> Array
```

`matmul` follows NumPy broadcasting rules. Dispatches to vendor
BLAS (`sgemm`/`dgemm`) for 2D float inputs above a size threshold.
Below the threshold, a direct loop is faster than BLAS call
overhead.

---

## Part 7: Sorting, Searching, Counting

```
fn sort(a: &Array, dim: i32 = -1, descending: bool = false) -> Array
fn argsort(a: &Array, dim: i32 = -1, descending: bool = false) -> Array
fn topk(a: &Array, k: i32, dim: i32 = -1, largest: bool = true) -> (Array, Array)
fn searchsorted(sorted: &Array, values: &Array, side: str = "left") -> Array
fn unique(a: &Array) -> Array
fn unique_with_counts(a: &Array) -> (Array, Array, Array)
fn bincount(a: &Array, minlength: i32 = 0) -> Array
fn histogram(a: &Array, bins: i32 = 10) -> (Array, Array)
fn nonzero(a: &Array) -> Array
fn count_nonzero(a: &Array, dim: i32 = -1) -> Array
```

---

## Part 8: Type Casting

```
fn to_dtype(a: &Array, dtype: DType) -> Array
fn float(a: &Array) -> Array          // → Float32
fn double(a: &Array) -> Array         // → Float64
fn half(a: &Array) -> Array           // → Float16
fn bfloat16(a: &Array) -> Array       // → BFloat16
fn int(a: &Array) -> Array            // → Int32
fn long(a: &Array) -> Array           // → Int64
fn bool_(a: &Array) -> Array          // → Bool (nonzero = true)
```

### Dtype promotion lattice

When binary operations combine different dtypes:

```
Rule 1: Same type → same type.
Rule 2: Integer widening: i8 → i16 → i32 → i64.
Rule 3: Unsigned widening: u8 → u16 → u32 → u64.
Rule 4: Float widening: f16 → f32 → f64. bf16 → f32.
Rule 5: Int + float → float.
Rule 6: Signed + unsigned → signed, next width if needed.
Rule 7: No silent narrowing. f64 + f32 → f64.
Rule 8: Scalars adopt the Array's dtype.
```

---

## Part 9: Indexing

Uses the language's multidimensional indexing syntax (F5) and
the `MultiIndex` trait.

### View vs copy rule

| Index type | Returns | Memory |
|---|---|---|
| Slice (`a[2:5]`, `a[::2]`) | View | Shares Storage |
| Ellipsis, newaxis | View | Shares Storage |
| Scalar + slice mix (`a[2, :]`) | View | Shares Storage |
| Boolean mask (`a[mask]`) | New Array | Allocates |
| Integer array (`a[indices]`) | New Array | Allocates |

If the result can be described by adjusting offset, shape, and
strides, it's a view. Otherwise it's a new allocation.

### Indexed assignment

```
var a = zeros(shape2(4, 4))
a[0, :] = 1.0                      // scalar broadcast
a[1:3, 1:3] = array_2d(...)        // array, broadcast-compatible
a[mask] = 0.0                      // mask scatter
a[indices] = values                 // index scatter
```

In-place if sole owner (refcount 1). Copy-on-write if shared.
Overlapping view assignments use overlap-safe copy (memmove
semantics).

### Negative indexing

`a[-1]` → last element. `a[-3:]` → last 3. `a[::-1]` → reversed.

---

## Part 10: Broadcasting

NumPy rules exactly:

1. Shapes right-aligned.
2. Size-1 dims expand to match.
3. Missing dims on left treated as size 1.

```
[3, 4] + [4]       → [3, 4]
[3, 1] + [1, 4]    → [3, 4]
[2, 3, 4] + [4]    → [2, 3, 4]
```

Broadcasting is implemented via views with stride=0 on expanded
dimensions. No data copy. The inner loops of elementwise ops
handle strided iteration natively.

Broadcast failures produce clear errors:

```
error: cannot broadcast shapes [3, 4] and [5]
  dimension 1: 4 != 5
```

---

## Part 11: Printing

```
println(f"{a}")
```

Produces:

```
Array[3, 4] f32
[[ 1.0000  2.0000  3.0000  4.0000]
 [ 5.0000  6.0000  7.0000  8.0000]
 [ 9.0000 10.0000 11.0000 12.0000]]
```

Rules:
- Header: shape + dtype.
- Right-aligned columns, uniform precision.
- Large arrays truncate with `...` (first 3 + last 3 per dim).
- 1D on one line. 0D shows scalar.
- Format specifiers: `f"{a:.2}"`, `f"{a:e}"`.

---

## Part 12: std.math.linalg

Wraps vendor BLAS/LAPACK via `c_import`. Does not reimplement
numerical linear algebra.

**macOS:** Accelerate framework (vecLib — includes BLAS + LAPACK).
**Linux:** OpenBLAS (ships widely, BSD-licensed) or MKL.
**Fallback:** Reference LAPACK if no vendor library found.

```
use std.math.linalg

// Norms and invariants
fn norm(a: &Array, ord: f64 = 2.0, dim: i32 = -1) -> Array
fn cond(a: &Array, p: f64 = 2.0) -> Array
fn trace(a: &Array) -> Array
fn det(a: &Array) -> Array
fn slogdet(a: &Array) -> (Array, Array)
fn matrix_rank(a: &Array, tol: f64 = -1.0) -> Array

// Decompositions
fn svd(a: &Array, full_matrices: bool = true) -> (Array, Array, Array)
fn eig(a: &Array) -> (Array, Array)
fn eigh(a: &Array) -> (Array, Array)
fn eigvals(a: &Array) -> Array
fn eigvalsh(a: &Array) -> Array
fn qr(a: &Array) -> (Array, Array)
fn lu(a: &Array) -> (Array, Array, Array)
fn cholesky(a: &Array) -> Array

// Solvers
fn solve(a: &Array, b: &Array) -> Array
fn lstsq(a: &Array, b: &Array) -> (Array, Array, Array, Array)
fn inv(a: &Array) -> Array
fn pinv(a: &Array) -> Array
fn matrix_power(a: &Array, n: i32) -> Array
fn matrix_exp(a: &Array) -> Array
```

### Implementation strategy

Each function:
1. Validates input shapes and dtypes.
2. Ensures input is contiguous (copies if needed — LAPACK requires
   column-major contiguous input).
3. Allocates output arrays.
4. Calls the corresponding LAPACK routine via `c_import`
   (`dgesdd` for SVD, `dpotrf` for Cholesky, `dgesv` for solve,
   etc.).
5. Wraps results in Array and returns.

The std.math wrapper handles all the LAPACK ceremony — work array
sizing, info code checking, row/column major conversion — so the
user never sees it.

---

## Part 13: std.math.random

Explicit RNG state for reproducibility. Thread-local convenience
for quick work.

```
use std.math.random

type Rng = opaque

fn rng(seed: u64) -> Rng
fn rng_fork(r: &mut Rng) -> Rng

// Explicit RNG (reproducible):
fn uniform(r: &mut Rng, shape: Shape, low: f64 = 0.0, high: f64 = 1.0,
           dtype: DType = Float32) -> Array
fn normal(r: &mut Rng, shape: Shape, mean: f64 = 0.0, std: f64 = 1.0,
          dtype: DType = Float32) -> Array
fn randint(r: &mut Rng, shape: Shape, low: i64, high: i64,
           dtype: DType = Int32) -> Array
fn bernoulli(r: &mut Rng, shape: Shape, p: f64 = 0.5) -> Array
fn exponential(r: &mut Rng, shape: Shape, rate: f64 = 1.0) -> Array
fn poisson(r: &mut Rng, shape: Shape, lam: f64 = 1.0) -> Array
fn permutation(r: &mut Rng, n: i32) -> Array
fn shuffle(r: &mut Rng, a: &mut Array)
fn choice(r: &mut Rng, a: &Array, n: i32, replace: bool = true) -> Array

// Convenience (thread-local default RNG):
fn rand(shape: Shape, dtype: DType = Float32) -> Array
fn randn(shape: Shape, dtype: DType = Float32) -> Array
fn rand_like(a: &Array) -> Array
fn randn_like(a: &Array) -> Array
```

### Implementation

Xoshiro256++ core generator. Box-Muller for normal distribution.
Thread-local default seeded from system entropy on first use.

---

## Part 14: std.math.stats

```
use std.math.stats

fn mean(a: &Array, dim: i32 = -1) -> Array
fn median(a: &Array, dim: i32 = -1) -> Array
fn var_(a: &Array, dim: i32 = -1, ddof: i32 = 0) -> Array
fn std_(a: &Array, dim: i32 = -1, ddof: i32 = 0) -> Array
fn quantile(a: &Array, q: f64, dim: i32 = -1) -> Array
fn percentile(a: &Array, p: f64, dim: i32 = -1) -> Array
fn nanmean(a: &Array, dim: i32 = -1) -> Array
fn nanmedian(a: &Array, dim: i32 = -1) -> Array
fn nanstd(a: &Array, dim: i32 = -1) -> Array
fn nanquantile(a: &Array, q: f64, dim: i32 = -1) -> Array

fn cov(a: &Array, b: &Array) -> Array
fn corrcoef(a: &Array, b: &Array) -> Array

fn histogram(a: &Array, bins: i32 = 10,
             range: (f64, f64) = (-inf, inf)) -> (Array, Array)
fn bincount(a: &Array, minlength: i32 = 0) -> Array

fn zscore(a: &Array, dim: i32 = -1) -> Array
fn normalize(a: &Array, dim: i32 = -1, ord: f64 = 2.0) -> Array
```

---

## Part 15: std.math.fft

Wraps vendor FFT libraries via `c_import`.

**macOS:** vDSP (part of Accelerate).
**Linux:** FFTW or pocketfft.
**Fallback:** pocketfft (pure C, no dependencies, BSD-licensed).

```
use std.math.fft

fn fft(a: &Array, n: i32 = -1, dim: i32 = -1) -> Array
fn ifft(a: &Array, n: i32 = -1, dim: i32 = -1) -> Array
fn rfft(a: &Array, n: i32 = -1, dim: i32 = -1) -> Array
fn irfft(a: &Array, n: i32 = -1, dim: i32 = -1) -> Array
fn fft2(a: &Array) -> Array
fn ifft2(a: &Array) -> Array
fn fftn(a: &Array) -> Array
fn ifftn(a: &Array) -> Array
fn fftfreq(n: i32, d: f64 = 1.0) -> Array
fn rfftfreq(n: i32, d: f64 = 1.0) -> Array
fn fftshift(a: &Array) -> Array
fn ifftshift(a: &Array) -> Array
```

---

## Part 16: std.math.signal

```
use std.math.signal

fn convolve(a: &Array, b: &Array, mode: str = "full") -> Array
fn correlate(a: &Array, b: &Array, mode: str = "full") -> Array
fn convolve2d(a: &Array, kernel: &Array, mode: str = "same") -> Array

fn hann(n: i32) -> Array
fn hamming(n: i32) -> Array
fn blackman(n: i32) -> Array
fn kaiser(n: i32, beta: f64) -> Array
fn gaussian_window(n: i32, std: f64) -> Array

fn stft(a: &Array, n_fft: i32 = 1024, hop: i32 = 256,
        window: &Array = hann(1024)) -> Array
fn istft(a: &Array, hop: i32 = 256, window: &Array = hann(1024)) -> Array

fn medfilt(a: &Array, kernel_size: i32 = 3) -> Array
fn savgol_filter(a: &Array, window_length: i32, polyorder: i32) -> Array
```

---

## Part 17: std.math.interpolate

```
use std.math.interpolate

fn interp(x: &Array, xp: &Array, fp: &Array) -> Array
fn interp_nearest(x: &Array, xp: &Array, fp: &Array) -> Array
fn interp_cubic(x: &Array, xp: &Array, fp: &Array) -> Array
fn grid_interp2d(x: &Array, y: &Array, z: &Array,
                 xi: &Array, yi: &Array, method: str = "linear") -> Array
```

---

## Part 18: std.math.optimize

```
use std.math.optimize

fn bisect(f: fn(f64) -> f64, a: f64, b: f64, tol: f64 = 1e-12) -> f64
fn newton(f: fn(f64) -> f64, fprime: fn(f64) -> f64,
          x0: f64, tol: f64 = 1e-12) -> f64
fn brentq(f: fn(f64) -> f64, a: f64, b: f64, tol: f64 = 1e-12) -> f64

fn least_squares(f: fn(&Array) -> Array, x0: &Array) -> Array
fn curve_fit(f: fn(&Array, &Array) -> Array, xdata: &Array,
             ydata: &Array, p0: &Array) -> (Array, Array)

fn minimize_scalar(f: fn(f64) -> f64, bounds: (f64, f64)) -> f64
fn minimize(f: fn(&Array) -> f64, x0: &Array,
            method: str = "L-BFGS-B") -> Array
```

---

## Part 19: std.math.integrate

```
use std.math.integrate

fn trapezoid(y: &Array, x: &Array, dim: i32 = -1) -> Array
fn simpson(y: &Array, x: &Array, dim: i32 = -1) -> Array
fn cumulative_trapezoid(y: &Array, x: &Array, dim: i32 = -1) -> Array
fn quad(f: fn(f64) -> f64, a: f64, b: f64) -> f64
```

---

## Part 20: std.math.special

```
use std.math.special

fn erf(a: &Array) -> Array
fn erfc(a: &Array) -> Array
fn erfinv(a: &Array) -> Array
fn gamma(a: &Array) -> Array
fn lgamma(a: &Array) -> Array
fn digamma(a: &Array) -> Array
fn beta(a: &Array, b: &Array) -> Array
fn bessel_j0(a: &Array) -> Array
fn bessel_j1(a: &Array) -> Array
fn bessel_i0(a: &Array) -> Array
fn bessel_i1(a: &Array) -> Array
fn softmax(a: &Array, dim: i32 = -1) -> Array
fn log_softmax(a: &Array, dim: i32 = -1) -> Array
fn logsumexp(a: &Array, dim: i32 = -1) -> Array
```

---

## Part 21: std.math.io

```
use std.math.io

// NumPy format
fn save_npy(path: str, a: &Array)
fn load_npy(path: str) -> Array
fn save_npz(path: str, arrays: &[(str, &Array)])
fn load_npz(path: str) -> HashMap[str, Array]

// CSV
fn load_csv(path: str, dtype: DType = Float64,
            delimiter: str = ",", skip_header: i32 = 0) -> Array
fn save_csv(path: str, a: &Array, delimiter: str = ",",
            header: &[str] = [])

// Binary
fn from_bytes(data: &[u8], dtype: DType, shape: Shape) -> Array
fn to_bytes(a: &Array) -> Vec[u8]

// Safetensors (ML weight format — interop with Weld ecosystem)
fn load_safetensors(path: str) -> HashMap[str, Array]
fn save_safetensors(path: str, tensors: &HashMap[str, &Array])

// Images (basic)
fn load_image(path: str) -> Array           // [H, W, C] u8
fn save_image(path: str, a: &Array)
```

---

## Part 22: Constants

```
let PI: f64 = 3.14159265358979323846
let E: f64 = 2.71828182845904523536
let TAU: f64 = 6.28318530717958647692
let INF: f64 = f64_infinity
let NAN: f64 = f64_nan
let NEWAXIS: IndexSpec = ...
```

---

## Part 23: What `use std.math` Imports

A curated surface of ~60 names:

**Constructors:** `array`, `zeros`, `ones`, `full`, `eye`,
`arange`, `linspace`, `zeros_like`, `ones_like`, `empty`.

**Elementwise:** `abs`, `exp`, `log`, `sqrt`, `sin`, `cos`, `tan`,
`tanh`, `sigmoid`, `pow`, `square`, `sign`, `ceil`, `floor`,
`round`, `clamp`, `maximum`, `minimum`, `where_`, `isnan`, `isinf`.

**Reductions:** `sum`, `mean`, `max`, `min`, `argmax`, `argmin`,
`any`, `all`, `prod`, `cumsum`, `norm`.

**Matrix:** `matmul`, `dot`, `outer`, `einsum`, `bmm`.

**Shape:** `reshape`, `transpose`, `squeeze`, `unsqueeze`,
`flatten`, `cat`, `stack`, `split`, `expand`, `contiguous`,
`clone`, `flip`, `t`.

**Sorting:** `sort`, `argsort`, `topk`, `unique`, `nonzero`.

**Type:** `to_dtype`, `float`, `half`, `int`, `item`.

**Properties:** `shape`, `dtype`, `ndim`, `numel`.

**Constants:** `PI`, `E`, `TAU`, `INF`, `NAN`, `NEWAXIS`.

Everything else stays namespaced:
`linalg.svd(...)`, `random.normal(...)`, `fft.fft(...)`,
`stats.median(...)`.

---

## Part 24: Compute Strategy

std.math has no GPU backend and no kernel compilation. All
computation runs on the CPU.

### Elementwise ops

Each elementwise operation is a compiled With function with a
tight inner loop over contiguous data. LLVM auto-vectorizes
these loops — With's codegen produces the same quality of inner
loop as hand-written C with `-O2 -march=native`.

For non-contiguous inputs (strided views), the inner loop uses
stride arithmetic. The general pattern:

```
fn add_kernel(a: &Array, b: &Array, out: &mut Array):
    let n = numel(a)
    let a_ptr = data_ptr(a)
    let b_ptr = data_ptr(b)
    let o_ptr = data_ptr(out)
    // contiguous fast path
    if is_contiguous(a) and is_contiguous(b):
        for i in 0..n:
            o_ptr[i] = a_ptr[i] + b_ptr[i]  // LLVM vectorizes
    else:
        // strided path
        for i in 0..n:
            o_ptr[out_offset(i)] = a_ptr[a_offset(i)] + b_ptr[b_offset(i)]
```

### Reductions

Sequential accumulation with Kahan summation for numerical
stability. Parallelism via thread pool for large arrays (>100K
elements) — split the array, reduce each chunk, merge.

### Matrix operations

For 2D float matmul above a size threshold (~64×64):
call vendor BLAS (`sgemm`/`dgemm`) via `c_import`. Below the
threshold, a direct triple loop is faster than BLAS call overhead.

This is the same strategy as NumPy: small matrices use C loops,
large matrices use BLAS.

### Threading

std.math may use a thread pool for parallelizing large operations
(elementwise on >1M elements, large reductions, parallel sort).
The thread pool is created lazily on first use. Thread count
defaults to CPU core count, configurable via environment variable.

Single-threaded by default for small arrays. The threshold for
engaging the thread pool is per-operation and tuned empirically.

---

## Part 25: What std.math Is NOT

**Not a GPU library.** GPU-accelerated math is handled by
non-standard libraries (Crux, Weld). std.math is CPU-only.

**Not an ML library.** No autograd, no modules, no training.

**Not a dataframe library.** No column labels, no groupby.

**Not a graph compiler.** Every operation is immediate.

**Not a visualization library.** No plotting.

**Not a symbolic engine.** No symbolic differentiation.

---

## Part 26: Design Decisions

| Decision | Rationale |
|---|---|
| CPU only, no device abstraction | stdlib should work everywhere with no external dependencies. GPU is a separate library concern. |
| One type (Array) | No fragmentation. Vector, matrix, batch — all Array. |
| Borrow inputs, own outputs | Auto-ref makes `&` invisible. No clones in user code. |
| Function-first | Greppable, composable. `sum(a, dim: 0)` not `a.sum(dim=0)`. |
| Heap allocation via With's allocator | No Crux Memory, no device handles. malloc/free (or With's own allocator). |
| Vendor BLAS/LAPACK via c_import | Don't compete with LAPACK. Wrap the best available. |
| NumPy broadcasting | Industry standard. |
| View ops share Storage | reshape/transpose are free. |
| COW on indexed assignment | Views are safe from surprise mutation. |
| Explicit RNG state | Reproducibility. Thread-local convenience for quick work. |
| NaN propagation (IEEE) | Scientists expect IEEE 754. |
| Named args everywhere | Readability. |
| Curated default import | ~60 names, not 600. Submodules for specialized functions. |
| LLVM auto-vectorization | With's codegen produces vectorizable loops. No hand-written SIMD. |
| Thread pool for large ops | Parallelism where it helps. Single-threaded for small arrays. |

---

## Part 27: Implementation Phases

### Phase 1: Foundation

Array type, Storage, ownership model, View. Constructors: `zeros`,
`ones`, `full`, `arange`, `linspace`, `eye`. Elementwise: `add`,
`sub`, `mul`, `div`, `neg`, `exp`, `log`, `sin`, `cos`, `sqrt`,
`abs`, `pow`, `maximum`, `minimum`, `where_`. Scalar-Array
operators. Reductions: `sum`, `mean`, `max`, `min`, `argmax`.
Shape ops: `reshape`, `transpose`, `squeeze`, `unsqueeze`,
`flatten`, `cat`, `stack`, `contiguous`, `clone`. Broadcasting
engine. Dtype promotion. Printing.

### Phase 2: Matrix + Indexing

`matmul` (@ operator), `dot`, `bmm`, `einsum`, `outer`. Multi-dim
indexing (view path + gather path). Indexed assignment with COW.
Sorting: `sort`, `argsort`, `topk`, `unique`, `nonzero`. More
elementwise: `tanh`, `sigmoid`, `relu`, `gelu`, `clamp`, `isnan`.

### Phase 3: linalg

BLAS integration (`sgemm`/`dgemm` for large matmul). LAPACK
integration: `svd`, `eig`, `eigh`, `qr`, `lu`, `cholesky`,
`solve`, `lstsq`, `inv`, `pinv`, `det`, `norm`.

### Phase 4: random + stats + fft

Xoshiro256++ RNG. `normal`, `uniform`, `randint`, `permutation`.
Statistics: `median`, `quantile`, `cov`, `corrcoef`, `histogram`.
FFT via vDSP/pocketfft.

### Phase 5: signal + interpolate + optimize + integrate + special

Convolution, windows, STFT. Interpolation. Root finding,
minimization. Trapezoid/Simpson. Special functions.

### Phase 6: I/O

.npy, .csv, .safetensors, .npz, basic image loading.
