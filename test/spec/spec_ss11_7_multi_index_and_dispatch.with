//! expect-stdout: ok

// Spec test: Section 11.7 - Multi-Index and `@` Dispatch.

use std.collections.IndexSpec
type Matrix {
    a00: i32,
    a01: i32,
    a10: i32,
    a11: i32,
    writes: i32,
}

impl Matrix:
    fn at(self: &Self, row: i64, col: i64) -> i32:
        if row == 0 and col == 0:
            return self.a00
        if row == 0 and col == 1:
            return self.a01
        if row == 1 and col == 0:
            return self.a10
        self.a11

    fn set_at(mut self: Self, row: i64, col: i64, value: i32) -> Unit:
        if row == 0 and col == 0:
            self.a00 = value
            return
        if row == 0 and col == 1:
            self.a01 = value
            return
        if row == 1 and col == 0:
            self.a10 = value
            return
        self.a11 = value

// §11.7: a spec is `Scalar(i)`, `Slice(start?, stop?, step?)`, `Ellipsis` or
// `NewAxis`; a scalar's index is read by matching it.
fn scalar_of(spec: &IndexSpec) -> i64:
    match spec:
        .Scalar(i) => i
        _ => panic("not a scalar spec")

impl MultiIndex[i32] for Matrix:
    fn multi_index(self: &Self, specs: &[IndexSpec], count: i32) -> i32:
        assert(count == 2)
        self.at(scalar_of(specs[0]), scalar_of(specs[1]))

impl MultiIndexMut[i32] for Matrix:
    fn multi_index_set(mut self: Self, specs: &[IndexSpec], count: i32, value: i32) -> Unit:
        assert(count == 2)
        self.set_at(scalar_of(specs[0]), scalar_of(specs[1]), value)
        self.writes = self.writes + 1

// The four forms a probe receives for `p[2:5, :, newaxis, ...]`.
fn check_probe_specs(specs: &[IndexSpec]):
    match specs[0]:
        .Slice(start, stop, step) =>
            assert(start.unwrap() == 2)
            assert(stop.unwrap() == 5)
            assert(step.is_none())
        _ => panic("first spec is a slice")
    match specs[1]:
        .Slice(start, stop, step) =>
            assert(start.is_none())
            assert(stop.is_none())
            assert(step.is_none())
        _ => panic("second spec is the full slice")
    match specs[2]:
        .NewAxis => ()
        _ => panic("third spec is newaxis")
    match specs[3]:
        .Ellipsis => ()
        _ => panic("fourth spec is the ellipsis")

type SpecProbe { marker: i32 }

impl MultiIndex[i32] for SpecProbe:
    fn multi_index(self: &Self, specs: &[IndexSpec], count: i32) -> i32:
        assert(count == 4)
        check_probe_specs(specs)
        self.marker

impl MultiIndexMut[i32] for SpecProbe:
    fn multi_index_set(mut self: Self, specs: &[IndexSpec], count: i32, value: i32) -> Unit:
        assert(count == 4)
        check_probe_specs(specs)
        self.marker = value + count

type Offset { value: i32 }

impl Offset:
    fn add(self: &Self, rhs: i32) -> Offset:
        Offset { value: self.value + rhs * 10 }

type Mat2 { a: i32, b: i32, c: i32, d: i32 }

impl Mat2:
    fn matmul(self: &Self, rhs: Mat2) -> Mat2:
        Mat2 {
            a: self.a * rhs.a + self.b * rhs.c,
            b: self.a * rhs.b + self.b * rhs.d,
            c: self.c * rhs.a + self.d * rhs.c,
            d: self.c * rhs.b + self.d * rhs.d,
        }

fn test_multi_index_read_write:
    var m = Matrix { a00: 1, a01: 2, a10: 3, a11: 4, writes: 0 }
    assert(m[1, 0] == 3)
    m[0, 1] = 9
    assert(m.a01 == 9)
    assert(m.writes == 1)

fn test_multi_index_specs:
    let probe = SpecProbe { marker: 77 }
    assert(probe[2:5, :, newaxis, ...] == 77)

fn test_multi_index_slice_assignment:
    var probe = SpecProbe { marker: 1 }
    probe[2:5, :, newaxis, ...] = 80
    assert(probe.marker == 84)

fn test_own_side_dispatch:
    // §11.7 (#2611, D166): Offset.add serves `Offset + i32` only;
    // `3 + Offset{...}` no longer dispatches to it reversed.
    let shifted = Offset { value: 4 } + 3
    assert(shifted.value == 34)

fn test_matmul_dispatch:
    let identity = Mat2 { a: 1, b: 0, c: 0, d: 1 }
    let m = Mat2 { a: 1, b: 2, c: 3, d: 4 }
    let result = identity @ m
    assert(result.a == 1)
    assert(result.b == 2)
    assert(result.c == 3)
    assert(result.d == 4)

fn main:
    test_multi_index_read_write()
    test_multi_index_specs()
    test_multi_index_slice_assignment()
    test_own_side_dispatch()
    test_matmul_dispatch()
    print("ok")
