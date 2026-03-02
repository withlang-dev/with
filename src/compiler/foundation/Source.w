// Wave 1 foundations: source text + line mapping.

use compiler.foundation.Ids

extern fn with_fs_read_file(path: str) -> str

type Source = {
    path: str,
    text: str,
    line_offsets: Vec[i32],
    file_id: FileId,
}

type SourceLocation = {
    line: i32, // 0-based
    col: i32, // 0-based byte column
}

fn Source.from_string(path: str, text: str, file_id: FileId) -> Source:
    Source {
        path,
        text,
        line_offsets: source_compute_line_offsets(text),
        file_id,
    }

fn Source.from_file(path: str, file_id: FileId) -> Source:
    let text = with_fs_read_file(path)
    Source.from_string(path, text, file_id)

fn Source.line_count(self: Source) -> i32:
    self.line_offsets.len() as i32

fn Source.offset_to_location(self: Source, offset: i32) -> SourceLocation:
    if offset <= 0:
        return SourceLocation { line: 0, col: 0 }

    var clamped = offset
    if clamped > self.text.len() as i32:
        clamped = self.text.len() as i32

    var lo = 0
    var hi = self.line_offsets.len() as i32
    while lo < hi:
        let mid = lo + ((hi - lo) / 2)
        if self.line_offsets.get(mid as i64) <= clamped:
            lo = mid + 1
        else:
            hi = mid

    let line = lo - 1
    let line_start = self.line_offsets.get(line as i64)
    SourceLocation {
        line,
        col: clamped - line_start,
    }

fn Source.line_text(self: Source, line: i32) -> str:
    if line < 0 or line >= self.line_offsets.len() as i32:
        return ""

    let start = self.line_offsets.get(line as i64)
    var end = self.text.len() as i32
    if line + 1 < self.line_offsets.len() as i32:
        end = self.line_offsets.get((line + 1) as i64)

    let slice = self.text.slice(start as i64, end as i64)
    if slice.len() > 0 and slice[slice.len() - 1] == 10:
        return slice.slice(0, (slice.len() - 1) as i64)
    slice

fn source_compute_line_offsets(text: str) -> Vec[i32]:
    var offsets = Vec.new()
    offsets.push(0)
    for i in 0..text.len():
        if text[i] == 10:
            offsets.push((i as i32) + 1)
    offsets
