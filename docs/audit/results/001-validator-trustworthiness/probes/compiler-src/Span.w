// Wave 1 foundations: source locations.
//
// Root `Span` now follows the foundation implementation shape.

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
