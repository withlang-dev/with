//! skip
// Spec test: Section 11.7 — Multi-Index and `@` Dispatch (formerly 25.104)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: generalized indexing syntax routes through MultiIndex
type Tensor { ... }
type TensorView { ... }
impl MultiIndex[TensorView] for Tensor:
    fn multi_index(self: &Self, specs: &[IndexSpec]) -> TensorView: ...
impl MultiIndexMut[f32] for Tensor:
    fn multi_index_set(self: &mut Self, specs: &[IndexSpec], value: f32): ...

fn test:
    let patch = tensor[2:5, :, newaxis]
    tensor[..., 0] = 1.0

// PASS: right-side operator dispatch and matmul
type Array { ... }
impl Add[f64, Array] for Array:
    fn add(self: &Self, lhs: &f64) -> Array: ...
impl MatMul[Array, Array] for Array:
    fn matmul(self: &Self, rhs: &Array) -> Array: ...

fn test:
    let shifted = 1.0 + arr
    let prod = a @ b
