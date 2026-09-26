// Release UAT: bzip2 through its facade (D64, spec §16.2b.8). The program an
// application developer writes over `with get c.bzip2`: the facade
// `facades.bzip2` is the project's own (§16.2b.1). No `unsafe`, no pointer,
// no length: the one-shot calls take two slices and the tuning integers,
// return the bytes they wrote, and leave the caller's buffers as they were.
use facades.bzip2
use c_import("bzlib.h")

fn main:
    let input = "with bzip2 roundtrip"
    var compressed: [u8; 512] = [0 as u8; 512]
    var output: [u8; 128] = [0 as u8; 128]

    let Ok(packed) = BZ2_bzBuffToBuffCompress(compressed, input as []u8, 9, 0, 30) else:
        print("bzip2 compress failed")
        return 1
    let Ok(unpacked) = BZ2_bzBuffToBuffDecompress(output, compressed[..packed], 0, 0) else:
        print("bzip2 decompress failed")
        return 1

    if unpacked != input.len() as usize:
        print("bzip2 length mismatch")
        return 1
    let bytes = input as []u8
    for i in 0..unpacked as i32:
        if output[i] != bytes[i]:
            print("bzip2 content mismatch")
            return 1
    print("bzip2 UAT passed")
