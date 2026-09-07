// Exact behavioral harness for src/Span.w at
// 31f77937abad3bc6573df3b71a0c99b605d6ea8e.

type FileId = i32

type Span {
    file: FileId,
    start: i32,
    end: i32,
}
impl Copy for Span

fn span_zero -> Span:
    Span {
        file: 0,
        start: 0,
        end: 0,
    }

fn Span.zero -> Span:
    span_zero()

impl Span:
    fn len() -> i32:
        self.end - self.start

    fn is_valid() -> bool:
        self.file >= 0 and self.start >= 0 and self.end >= self.start

    fn merge(other: &Span) -> Span:
        Span {
            file: self.file,
            start: span_min_i32(self.start, other.start),
            end: span_max_i32(self.end, other.end),
        }

fn span_min_i32(a: i32, b: i32) -> i32:
    if a < b:
        return a
    b

fn span_max_i32(a: i32, b: i32) -> i32:
    if a > b:
        return a
    b

fn assert_span(actual: Span, file: i32, start: i32, end: i32):
    assert(actual.file == file)
    assert(actual.start == start)
    assert(actual.end == end)

fn main:
    assert_span(span_zero(), 0, 0, 0)
    assert_span(Span.zero(), 0, 0, 0)

    let point = Span { file: 0, start: 7, end: 7 }
    assert(point.len() == 0)
    assert(point.is_valid())

    let ordinary = Span { file: 3, start: 2, end: 8 }
    assert(ordinary.len() == 6)
    assert(ordinary.is_valid())

    let widest_valid = Span { file: 2147483647, start: 0, end: 2147483647 }
    assert(widest_valid.len() == 2147483647)
    assert(widest_valid.is_valid())

    assert(not Span { file: -1, start: 0, end: 0 }.is_valid())
    assert(not Span { file: 0, start: -1, end: 0 }.is_valid())
    assert(not Span { file: 0, start: 2, end: 1 }.is_valid())

    let overlap = ordinary.merge(Span { file: 3, start: 1, end: 4 })
    assert_span(overlap, 3, 1, 8)
    let disjoint = ordinary.merge(Span { file: 3, start: 20, end: 30 })
    assert_span(disjoint, 3, 2, 30)
    let reverse = Span { file: 3, start: 20, end: 30 }.merge(ordinary)
    assert_span(reverse, 3, 2, 30)
    let cross_file = ordinary.merge(Span { file: 9, start: 1, end: 30 })
    assert_span(cross_file, 3, 1, 30)

    let copied = ordinary
    assert_span(copied, 3, 2, 8)
    assert_span(ordinary, 3, 2, 8)

    print("span-matrix: ok")
