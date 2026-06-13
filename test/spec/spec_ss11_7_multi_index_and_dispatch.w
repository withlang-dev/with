//! expect-stdout: ok

// Spec test: Section 11.7 - Multi-Index and `@` Dispatch.

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

impl MultiIndex[i32] for Matrix:
    fn multi_index(self: &Self, specs: &[IndexSpec], count: i32) -> i32:
        assert(count == 2)
        let row = specs[0]
        let col = specs[1]
        assert(row.kind == 0)
        assert(col.kind == 0)
        assert(row.has_start)
        assert(col.has_start)
        self.at(row.start, col.start)

impl MultiIndexMut[i32] for Matrix:
    fn multi_index_set(mut self: Self, specs: &[IndexSpec], count: i32, value: i32) -> Unit:
        assert(count == 2)
        let row = specs[0]
        let col = specs[1]
        assert(row.kind == 0)
        assert(col.kind == 0)
        self.set_at(row.start, col.start, value)
        self.writes = self.writes + 1

type SpecProbe { marker: i32 }

impl MultiIndex[i32] for SpecProbe:
    fn multi_index(self: &Self, specs: &[IndexSpec], count: i32) -> i32:
        assert(count == 4)
        let range = specs[0]
        let full = specs[1]
        let axis = specs[2]
        let dots = specs[3]
        assert(range.kind == 1)
        assert(range.has_start)
        assert(range.has_stop)
        assert(not range.has_step)
        assert(range.start == 2)
        assert(range.stop == 5)
        assert(full.kind == 1)
        assert(not full.has_start)
        assert(not full.has_stop)
        assert(axis.kind == 3)
        assert(dots.kind == 2)
        self.marker

impl MultiIndexMut[i32] for SpecProbe:
    fn multi_index_set(mut self: Self, specs: &[IndexSpec], count: i32, value: i32) -> Unit:
        assert(count == 4)
        let range = specs[0]
        let full = specs[1]
        let axis = specs[2]
        let dots = specs[3]
        assert(range.kind == 1)
        assert(range.has_start)
        assert(range.has_stop)
        assert(not range.has_step)
        assert(range.start == 2)
        assert(range.stop == 5)
        assert(full.kind == 1)
        assert(not full.has_start)
        assert(not full.has_stop)
        assert(axis.kind == 3)
        assert(dots.kind == 2)
        self.marker = value + count

type Offset { value: i32 }

impl Offset:
    fn add(self: Offset, lhs: i32) -> Offset:
        Offset { value: self.value + lhs * 10 }

type Mat2 { a: i32, b: i32, c: i32, d: i32 }

impl Mat2:
    fn matmul(self: Mat2, rhs: Mat2) -> Mat2:
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

fn test_right_side_dispatch:
    let shifted = 3 + Offset { value: 4 }
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
    test_right_side_dispatch()
    test_matmul_dispatch()
    print("ok")
