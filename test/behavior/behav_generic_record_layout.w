//! expect-stdout: ok

type Record[T] { value: T, next: *mut Record[T] }
type Pair[A, B] { first: A, second: B }

fn record_size[T](value: &T): sizeof[Record[T]]()
fn record_align[T](value: &T): alignof[Record[T]]()
fn pair_size[A, B](first: &A, second: &B): sizeof[Pair[A, B]]()
fn nested_size[T](value: &T): sizeof[Record[Record[T]]]()
fn optional_size[T](value: &T): sizeof[Option[T]]()

fn main:
    assert(record_size(7) == sizeof[Record[i32]]())
    assert(record_size("value") == sizeof[Record[str]]())
    assert(record_align(7) == alignof[Record[i32]]())
    assert(record_align("value") == alignof[Record[str]]())
    assert(pair_size(7, "value") == sizeof[Pair[i32, str]]())
    assert(pair_size("value", 7) == sizeof[Pair[str, i32]]())
    assert(nested_size(7) == sizeof[Record[Record[i32]]]())
    assert(optional_size(7) == sizeof[Option[i32]]())
    print("ok")
