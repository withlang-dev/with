extern fn with_fs_read_file(path: &str) -> str
extern fn with_str_clone_ref(s: &str) -> str

use std.process

type Source {
    path: str,
    text: str,
    line_offsets: Vec[i32],
    file_id: i32,
}

type SourceLocation {
    line: i32,
    col: i32,
}

type Location = SourceLocation

unsafe fn Source.from_string(path: &str, text: &str, file_id: i32) -> Source:
    Source {
        path: with_str_clone_ref(path),
        text: with_str_clone_ref(text),
        line_offsets: source_compute_line_offsets(text),
        file_id,
    }

unsafe fn Source.from_file(path: &str, file_id: i32) -> Source:
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

    fn line_text(line: i32) -> str:
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

fn source_compute_line_offsets(text: &str) -> Vec[i32]:
    var offsets: Vec[i32] = Vec.new()
    offsets.push(0)
    for i in 0..text.len():
        if text[i] == 10:
            offsets.push((i as i32) + 1)
    offsets

impl Source:
    fn deinit():
        return

unsafe fn check_empty():
    let src = Source.from_string("empty.w", "", 7)
    assert(src.path == "empty.w")
    assert(src.text == "")
    assert(src.file_id == 7)
    assert(src.line_count() == 1)
    let neg = src.offset_to_location(-999)
    let zero = src.offset_to_location(0)
    let past = src.offset_to_location(999)
    assert(neg.line == 0 and neg.col == 0)
    assert(zero.line == 0 and zero.col == 0)
    assert(past.line == 0 and past.col == 0)
    assert(src.line_text(-1) == "")
    assert(src.line_text(0) == "")
    assert(src.line_text(1) == "")

unsafe fn check_lf_boundaries():
    let src = Source.from_string("lf.w", "ab\ncd", 8)
    assert(src.line_count() == 2)
    let o0 = src.offset_to_location(0)
    let o1 = src.offset_to_location(1)
    let o2 = src.offset_to_location(2)
    let o3 = src.offset_to_location(3)
    let o5 = src.offset_to_location(5)
    let past = src.offset_to_location(99)
    assert(o0.line == 0 and o0.col == 0)
    assert(o1.line == 0 and o1.col == 1)
    assert(o2.line == 0 and o2.col == 2)
    assert(o3.line == 1 and o3.col == 0)
    assert(o5.line == 1 and o5.col == 2)
    assert(past.line == 1 and past.col == 2)
    assert(src.line_text(0) == "ab")
    assert(src.line_text(1) == "cd")

    let trailing = Source.from_string("trailing.w", "\n", 9)
    assert(trailing.line_count() == 2)
    assert(trailing.line_text(0) == "")
    assert(trailing.line_text(1) == "")
    let eof = trailing.offset_to_location(1)
    assert(eof.line == 1 and eof.col == 0)

unsafe fn check_utf8_crlf():
    let src = Source.from_string("unicode.w", "aé\r\nb😀\r\n", 10)
    assert(src.line_count() == 3)
    let after_a = src.offset_to_location(1)
    let cr0 = src.offset_to_location(3)
    let line1 = src.offset_to_location(5)
    let emoji = src.offset_to_location(6)
    let cr1 = src.offset_to_location(10)
    let eof = src.offset_to_location(12)
    assert(after_a.line == 0 and after_a.col == 1)
    assert(cr0.line == 0 and cr0.col == 3)
    assert(line1.line == 1 and line1.col == 0)
    assert(emoji.line == 1 and emoji.col == 1)
    assert(cr1.line == 1 and cr1.col == 5)
    assert(eof.line == 2 and eof.col == 0)
    assert(src.line_text(0) == "aé\r")
    assert(src.line_text(1) == "b😀\r")
    assert(src.line_text(2) == "")
    assert(src.line_text(2147483647) == "")

unsafe fn check_file():
    let src = Source.from_file("test/internals/span_source_test.w", 11)
    assert(src.path == "test/internals/span_source_test.w")
    assert(src.file_id == 11)
    assert(src.line_count() > 20)
    assert(src.line_text(0) == "//! expect-stdout: ok")
    assert(src.line_text(1) == "")
    assert(src.text.contains("use compiler.foundation.Source"))

fn main:
    unsafe:
        let argv = args()
        let mode = if argv.len() > 1: argv.get(1) else: "all"
        if mode == "all" or mode == "empty": check_empty()
        if mode == "all" or mode == "lf": check_lf_boundaries()
        if mode == "all" or mode == "utf8": check_utf8_crlf()
        if mode == "all" or mode == "file": check_file()
        print("source-matrix: ok")
