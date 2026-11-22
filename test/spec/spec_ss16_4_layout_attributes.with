//! expect-stdout: ok

// §16.4 layout attributes: repr(C), repr(packed), and field @[align].

@[repr(C)]
type Point {
    x: i32,
    y: i32,
}

@[repr(packed)]
type Packed {
    a: u8,
    b: i32,
}

type Aligned {
    @[align(16)] v: i32,
}

fn main:
    if sizeof[Point]() == 8 and sizeof[Packed]() == 5 and alignof[Aligned]() == 16:
        print("ok")
    else:
        print("bad")
