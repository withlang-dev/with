use demo.core

pub enum DType: i32:
    Int32 = 2

pub type Shape {
    d0: Size,
    rank: i32,
}

pub type View {
    memory: Memory,
    shape: Shape,
    dtype: DType,
}

pub fn shape1(d0: Size) -> Shape:
    Shape { d0, rank: 1 }

pub fn shape_scalar() -> Shape:
    Shape { d0: 1usize, rank: 0 }

pub fn view_contiguous(mem: Memory, shape: Shape, dtype: DType) -> View:
    View { memory: mem, shape, dtype }

pub fn view_elem_count(view: View) -> Size:
    if view.shape.rank == 0:
        return 1usize
    view.shape.d0
