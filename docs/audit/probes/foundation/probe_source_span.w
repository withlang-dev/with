// T13 source/span OOB directions + T23 duplicate-path failure mode.
use compiler.foundation.Ids
use compiler.foundation.Source
use compiler.foundation.SourceMap
use compiler.foundation.Span

extern fn with_print_str(s: &str) -> Unit

fn main:
    var sm = SourceMap.init()
    let f1 = sm.add_source_text("a.w", "line1\nline2\nline3")
    let f2 = sm.add_source_text("a.w", "DIFFERENT")
    unsafe { with_print_str(f"f1={file_id_raw(f1)} dup_same={f1 == f2}\n") }
    let loc0 = sm.offset_to_location(f1, 0)
    let locneg = sm.offset_to_location(f1, -5)
    let locbig = sm.offset_to_location(f1, 99999)
    unsafe { with_print_str(f"loc0={loc0.line}:{loc0.col} locneg={locneg.line}:{locneg.col} locbig={locbig.line}:{locbig.col}\n") }
    unsafe { with_print_str(f"line1=[{sm.line_text(f1, 1)}] lineOOB=[{sm.line_text(f1, 99)}] lineNeg=[{sm.line_text(f1, -1)}]\n") }
    // invalid file falls back to sentinel, never traps
    let bad = file_id_invalid()
    let bloc = sm.offset_to_location(bad, 3)
    unsafe { with_print_str(f"containsBad={sm.contains(bad)} badloc={bloc.line}:{bloc.col} badline=[{sm.line_text(bad, 0)}]\n") }
    // span algebra
    let s1 = Span { file: f1, start: 2, end: 5 }
    let s2 = Span { file: f1, start: 4, end: 9 }
    let m = s1.merge(s2)
    unsafe { with_print_str(f"merged={m.start}:{m.end} len={s1.len()} valid={s1.is_valid()}\n") }
    let z = span_zero()
    unsafe { with_print_str(f"zero_valid={z.is_valid()} zero_len={z.len()}\n") }
    // backwards span is invalid; merge keeps caller's file (no cross-file check)
    let bw = Span { file: f1, start: 9, end: 2 }
    let other = Span { file: f2, start: 0, end: 1 }
    let mx = s1.merge(other)
    unsafe { with_print_str(f"bw_valid={bw.is_valid()} bw_len={bw.len()} crossfile={file_id_raw(mx.file)}\n") }
