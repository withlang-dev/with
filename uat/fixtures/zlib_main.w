// Release UAT: zlib through its facade (D64, spec §16.2b.8). The program an
// application developer writes over `with get c.zlib`: the facade
// `facades.zlib` is the project's own (§16.2b.1). No `unsafe`, no pointer,
// no length: `compress(dest, src)` takes two slices and returns the bytes it
// wrote, `uncompress` the same, and the caller's buffers are what they were.
use facades.zlib
use c_import("zlib.h")

fn main:
    let input = "with zlib roundtrip"
    var compressed: [u8; 256] = [0 as u8; 256]
    var output: [u8; 128] = [0 as u8; 128]

    let Ok(packed) = compress(compressed, input as []u8) else:
        print("zlib compress failed")
        return 1
    let Ok(unpacked) = uncompress(output, compressed[..packed]) else:
        print("zlib uncompress failed")
        return 1

    if unpacked != input.len() as usize:
        print("zlib length mismatch")
        return 1
    let bytes = input as []u8
    for i in 0..unpacked as i32:
        if output[i] != bytes[i]:
            print("zlib content mismatch")
            return 1
    if zlibVersion().is_none():
        print("zlib version missing")
        return 1
    print("zlib UAT passed")
