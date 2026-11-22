//! expect-stdout: ok

type GenericBox[T] {
    value: T,
}

unsafe fn generic_box_read[T](box: *const GenericBox[T]) -> T:
    unsafe (*box).value

unsafe fn generic_box_write[T](box: *mut GenericBox[T], value: T) -> Unit:
    ((unsafe *box).value = value)

fn main:
    var box: GenericBox[i32] = GenericBox { value: 1 }
    let ptr = &raw mut box as *mut GenericBox[i32]
    unsafe:
        generic_box_write(ptr, 7)
        assert(generic_box_read(ptr as *const GenericBox[i32]) == 7)
    print("ok")
