//! expect-stdout: 163840 ok

// Repeated self-append crossing RT_LARGE_THRESHOLD (4096 bytes): the
// move-first concat reallocates with geometric headroom, so content must
// be preserved across many in-place appends and reallocation boundaries.
fn main:
    var s = ""
    var i = 0
    while i < 10240:
        s = s ++ "0123456789abcdef"
        i = i + 1
    if s.len() != 163840:
        print("length mismatch")
        return 1
    // First byte of the first chunk, last byte of the last chunk, and a
    // chunk boundary far past the threshold.
    if s.byte_at(0) != 48 or s.byte_at(s.len() - 1) != 102:
        print("edge content mismatch")
        return 1
    if s.byte_at(81920) != 48 or s.byte_at(81935) != 102:
        print("interior content mismatch")
        return 1
    print(f"{s.len()} ok")
