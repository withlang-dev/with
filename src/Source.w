// Source — Source file loading and line offset table.
//
// Provides source text management, line/column lookup for
// diagnostics, and file identity tracking.
//
// Ref: bootstrap/Source.zig

use Span

// ── Source file ──────────────────────────────────────────────────────

type SourceFile = {
    name: str,
    text: str,
    line_offsets: Vec[i32],
    file_id: i32,
}

fn SourceFile.new(name: str, text: str, file_id: i32) -> SourceFile:
    var sf = SourceFile {
        name: name,
        text: text,
        line_offsets: Vec.new(),
        file_id: file_id,
    }
    // Compute line offsets
    SourceFile.compute_line_offsets(sf)
    sf

fn SourceFile.compute_line_offsets(self: SourceFile) -> void:
    self.line_offsets.push(0)
    let len = self.text.len()
    var i = 0
    while i < len:
        if self.text[i] == 10:
            self.line_offsets.push((i + 1) as i32)
        i = i + 1

fn SourceFile.line_count(self: SourceFile) -> i32:
    self.line_offsets.len() as i32

// Find the line number (0-based) for a byte offset.
fn SourceFile.line_at(self: SourceFile, offset: i32) -> i32:
    let count = self.line_offsets.len() as i32
    var lo = 0
    var hi = count - 1
    while lo <= hi:
        let mid = (lo + hi) / 2
        let mid_offset = self.line_offsets.get(mid as i64)
        if mid_offset <= offset:
            lo = mid + 1
        if mid_offset > offset:
            hi = mid - 1
    lo - 1

// Find the column (0-based) for a byte offset.
fn SourceFile.col_at(self: SourceFile, offset: i32) -> i32:
    let line = SourceFile.line_at(self, offset)
    let line_start = self.line_offsets.get(line as i64)
    offset - line_start

// Get line and column as (line, col) for a span start.
fn SourceFile.line_col(self: SourceFile, offset: i32) -> i32:
    // Returns encoded: line * 10000 + col
    let line = SourceFile.line_at(self, offset)
    let col = SourceFile.col_at(self, offset)
    line * 10000 + col

// Extract a line of text by line number (0-based).
fn SourceFile.get_line_text(self: SourceFile, line: i32) -> str:
    let count = self.line_offsets.len() as i32
    if line < 0:
        return ""
    if line >= count:
        return ""
    let start = self.line_offsets.get(line as i64)
    var end = self.text.len() as i32
    if line + 1 < count:
        end = self.line_offsets.get((line + 1) as i64)
    // Trim trailing newline
    if end > start:
        if self.text[end - 1] == 10:
            end = end - 1
    self.text.slice(start as i64, end as i64)
