//! expect-error: dependency loop

// #1430: codegen now defines a type's body when it is first referenced; a
// by-value cycle through an enum payload (here declared before the struct
// that closes it) is still an infinite-size type, rejected by Sema before any
// body is laid out.

enum Shape:
    Boxed(inner: Frame)
    Empty

type Frame {
    shape: Shape,
    width: i32,
}

fn main:
    print("should not compile")
