//! expect-stdout: 5
//! expect-stdout: 6
//! expect-stdout: 7

// §16.6, §22.1 (#1833): a callable type holds no reference its signature
// names. `extern "C" fn(&i32) -> i32` takes a view per call and holds none,
// so a struct field, and a List element, of that type is not ephemeral. The
// field was refused: "ephemeral references cannot be stored in structs".

type Holder { f: extern "C" fn(&i32) -> i32, g: fn(&i32) -> i32 }

fn read(x: &i32) -> i32: *x
fn read_plus(x: &i32) -> i32: *x + 1

fn main:
    let h = Holder { f: read, g: read_plus }
    let v = 5
    print(f"{(h.f)(&v)}")
    print(f"{(h.g)(&v)}")
    let fs: List[extern "C" fn(&i32) -> i32] = [read_plus]
    let w = 6
    print(f"{fs[0](&w)}")
