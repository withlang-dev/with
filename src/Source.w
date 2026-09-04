// Wave 1 foundations: source text + line mapping.
//
// Root `Source` now follows the foundation implementation shape.

extern fn with_fs_read_file(path: &str) -> str
extern fn with_str_clone_ref(s: &str) -> str

type Source {
    path: str,
    text: str,
    line_offsets: Vec[i32],
    file_id: i32,
}

type SourceLocation {
    line: i32, // 0-based
    col: i32, // 0-based byte column
}

// Keep historical alias name for callers/tests.
type Location = SourceLocation

fn Source.from_string(path: &str, text: &str, file_id: i32) -> Source:
    Source {
        path: with_str_clone_ref(path),
        text: with_str_clone_ref(text),
        line_offsets: source_compute_line_offsets(text),
        file_id,
    }

fn Source.from_file(path: &str, file_id: i32) -> Source:
    let text = with_fs_read_file(path)
    Source.from_string(path, text, file_id)

impl Source:
    fn line_count() -> i32:
        self.line_offsets.len() as i32

    fn offset_to_location(offset: i32) -> SourceLocation:
        if offset <= 0:
            return SourceLocation { line: 0, col: 0 }

        var clamped = offset
        if clamped > self.text.len() as i32:
            clamped = self.text.len() as i32

        var lo = 0
        var hi = self.line_offsets.len() as i32
        while lo < hi:
            let mid = lo + ((hi - lo) / 2)
            if self.line_offsets[mid] <= clamped:
                lo = mid + 1
            else:
                hi = mid

        let line = lo - 1
        let line_start = self.line_offsets[line]
        SourceLocation {
            line,
            col: clamped - line_start,
        }

    fn line_text(line: i32) -> str:
        if line < 0 or line >= self.line_offsets.len() as i32:
            return ""

        let start = self.line_offsets[line]
        var end = self.text.len() as i32
        if line + 1 < self.line_offsets.len() as i32:
            end = self.line_offsets[(line + 1)]

        let slice = self.text.slice(start as i64, end as i64)
        if slice.len() > 0 and slice[slice.len() - 1] == 10:
            return slice.slice(0, (slice.len() - 1) as i64)
        slice

fn source_compute_line_offsets(text: &str) -> Vec[i32]:
    var offsets: Vec[i32] = Vec.new()
    offsets.push(0)
    for i in 0..text.len():
        if text[i] == 10:
            offsets.push((i as i32) + 1)
    offsets

impl Source:
    fn deinit():
        // No-op in current runtime model.
        return
