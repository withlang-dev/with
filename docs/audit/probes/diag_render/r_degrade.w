// diag_render degrade probe: exact inline copy of the Source.w mapping fns
// + the Diagnostic.w:119-125 render_at_offset clamp logic, exercised at
// the degrade edges (missing/empty/inverted spans, unicode byte cols).
// Run: out/bootstrap/bin/with-stage1 run .audit/probes/diag_render/r_degrade.w
use std.builtins.print_i32

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

fn Source.from_string(path: &str, text: &str, file_id: i32) -> Source:
    Source {
        path: path ++ "",
        text: text ++ "",
        line_offsets: source_compute_line_offsets(text),
        file_id,
    }

impl Source:
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
        SourceLocation { line, col: clamped - line_start }

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

// Mirror of Diagnostic.w:119-125 clamp block.
fn clamp_span(start: i32, end: i32, gen_start: i32) -> str:
    var pstart = start - gen_start
    if pstart < 0:
        pstart = 0
    var pend = end - gen_start
    if pend <= pstart:
        pend = pstart + 1
    f"{pstart}..{pend}"

fn show_loc(tag: &str, loc: SourceLocation):
    print(tag ++ f" line={loc.line} col={loc.col}")

fn main:
    let src = Source.from_string("a.w", "ab\ncdef\n", 0)
    // offset edges: <=0 pins to 0:0; past-EOF clamps to len
    show_loc("neg", src.offset_to_location(-3))
    show_loc("zero", src.offset_to_location(0))
    show_loc("far", src.offset_to_location(999))
    show_loc("mid2", src.offset_to_location(4))
    // line_text edges: out-of-range -> ""
    print("[" ++ src.line_text(-1) ++ "]")
    print("[" ++ src.line_text(99) ++ "]")
    print("[" ++ src.line_text(0) ++ "]")
    print("[" ++ src.line_text(1) ++ "]")
    // empty source: every offset pins, line 0 text is ""
    let empty = Source.from_string("e.w", "", 0)
    show_loc("empty", empty.offset_to_location(5))
    print("[" ++ empty.line_text(0) ++ "]")
    // render_at_offset clamps (Diagnostic.w:119-125)
    print(clamp_span(2, 2, 0))
    print(clamp_span(8, 2, 0))
    print(clamp_span(1, 4, 10))
    // unicode: col is BYTE-based; 2 CJK chars = 6 bytes
    let u = Source.from_string("u.w", "ab\xE4\xB8\xAD\xE6\x96\x87xy\n", 0)
    show_loc("after-cjk", u.offset_to_location(8))
    print("[" ++ u.line_text(0) ++ "]")
