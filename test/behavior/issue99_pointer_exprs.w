//! expect-stdout: ok

type Frame { ovector: [4]u64 = [0 as u64; 4], eptr: *const u8 = null }
type MatchBlock { start_subject: *const u8 = null }

fn main:
    var buf: [4]u8 = [0 as u8; 4]
    var code: *mut u8 = (&mut buf[0] as *mut u8)
    unsafe:
        *(code = code + 1) = 7 as u8
    assert(buf[1] == 7 as u8)

    var frame = Frame { ovector: [0 as u64, 2 as u64, 4 as u64, 6 as u64], eptr: null }
    var subject: [8]u8 = [0 as u8; 8]
    var mbv = MatchBlock { start_subject: (&subject[0] as *const u8) }
    let F: *mut Frame = &mut frame
    let mb: *mut MatchBlock = &mut mbv
    let offset: u64 = 1 as u64
    let p = (mb.start_subject + (&F.ovector[0] as *mut u64)[offset])
    let delta = (p as usize -% mb.start_subject as usize)
    assert(delta == 2 as usize)

    var x: u32 = 2149384192 as u32
    let px: *mut u32 = &mut x
    let ppx: *mut *mut u32 = &mut px
    let cmp = if unsafe: (*unsafe: *ppx) == 2149384192 as u32: 1 else: 0
    assert(cmp == 1)

    print("ok")
