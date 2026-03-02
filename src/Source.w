// Source file storage and offset-to-location mapping.
//
// Source owns the text content of a loaded file and provides
// efficient offset -> line/column translation via a precomputed
// line-start table.

extern fn with_fs_read_file(path: str) -> str

type Source = {
    // Human-readable file path (for diagnostics).
    name: str,
    // The full source text.
    text: str,
    // Byte offsets where each line begins (0-indexed lines).
    line_offsets: Vec[i32],
    // Identifier used in diagnostics.
    file_id: i32,
    // Whether we conceptually own the text buffer.
    owns_text: bool,
}

type Location = {
    line: i32, // 0-indexed
    col: i32, // 0-indexed, byte offset within line
}

// Build the line-offset table from source text.
fn Source.compute_line_offsets(text: str) -> Vec[i32]:
    var offsets = Vec.new()
    offsets.push(0) // line 0 starts at byte 0
    for i in 0..text.len():
        if text[i] == 10:
            offsets.push(i + 1)
    offsets

// Create a Source from a file path.
fn Source.from_file(path: str, file_id: i32) -> Source:
    let text = with_fs_read_file(path)
    Source {
        name: path,
        text,
        line_offsets: Source.compute_line_offsets(text),
        file_id,
        owns_text: true,
    }

// Create a Source from an in-memory string (useful for tests).
fn Source.from_string(name: str, text: str, file_id: i32) -> Source:
    Source {
        name,
        text,
        line_offsets: Source.compute_line_offsets(text),
        file_id,
        owns_text: false,
    }

// Convert a byte offset to a line/column location.
fn Source.offset_to_location(self: Source, offset: i32) -> Location:
    // Binary search for the line containing offset.
    var lo = 0
    var hi = self.line_offsets.len() as i32
    while lo < hi:
        let mid = lo + ((hi - lo) / 2)
        if self.line_offsets.get(mid as i64) <= offset:
            lo = mid + 1
        else:
            hi = mid
    let line = lo - 1
    let col = offset - self.line_offsets.get(line as i64)
    Location { line, col }

// Extract the source line that contains the given line index.
fn Source.line_text(self: Source, line: i32) -> str:
    let start = self.line_offsets.get(line as i64)
    var end = self.text.len()
    if line + 1 < self.line_offsets.len() as i32:
        end = self.line_offsets.get((line + 1) as i64)

    let slice = self.text.slice(start as i64, end as i64)
    if slice.len() > 0 and slice[slice.len() - 1] == 10:
        return slice.slice(0, (slice.len() - 1) as i64)
    slice

fn Source.deinit(self: Source):
    // No-op in current runtime model.
    return
