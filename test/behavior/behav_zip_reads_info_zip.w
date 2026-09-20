//! skip-on: windows issue #800: action/capability/net/process/fs OS-surface fails on native Windows
//! expect-stdout: ok

use pre_d_build_runner
use std.fs
use std.libc
use std.string
use std.zip

// std.zip reads an archive another implementation wrote: Info-ZIP's
// `zip -X -r t.zip top` over a directory, a stored file, an executable
// script and a deflated 9490-byte file (300 lines). Reading goes through
// the migrated minizip reader (std.zl.unzip), which checks each CRC-32.
fn fixture() -> Vec[u8]:
    [
     80, 75, 3, 4, 10, 0, 0, 0, 0, 0, 7, 153, 51, 93, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 4, 0, 0, 0, 116, 111, 112, 47, 80, 75, 3, 4, 10, 0, 0, 0, 0, 0, 7, 153, 51, 93,
     16, 169, 201, 169, 19, 0, 0, 0, 19, 0, 0, 0, 10, 0, 0, 0, 116, 111, 112, 47, 114, 117, 110, 46,
     115, 104, 35, 33, 47, 98, 105, 110, 47, 115, 104, 10, 101, 99, 104, 111, 32, 114, 97, 110, 10, 80, 75, 3,
     4, 10, 0, 0, 0, 0, 0, 7, 153, 51, 93, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8,
     0, 0, 0, 116, 111, 112, 47, 115, 117, 98, 47, 80, 75, 3, 4, 20, 0, 0, 0, 8, 0, 7, 153, 51,
     93, 228, 61, 90, 63, 232, 2, 0, 0, 18, 37, 0, 0, 15, 0, 0, 0, 116, 111, 112, 47, 115, 117, 98,
     47, 98, 105, 103, 46, 116, 120, 116, 133, 217, 205, 109, 220, 64, 16, 5, 225, 187, 163, 96, 8, 124, 69, 206,
     112, 24, 142, 109, 172, 128, 5, 86, 150, 33, 229, 15, 8, 14, 192, 175, 206, 125, 43, 240, 167, 63, 244, 235,
     249, 231, 177, 237, 219, 199, 219, 246, 115, 251, 253, 241, 254, 247, 243, 241, 245, 245, 252, 245, 122, 108, 111, 207,
     215, 227, 199, 235, 223, 52, 117, 74, 157, 30, 117, 122, 214, 233, 168, 211, 89, 167, 87, 157, 174, 58, 189, 123,
     13, 137, 213, 107, 165, 231, 74, 239, 149, 30, 44, 189, 88, 122, 178, 244, 102, 233, 209, 210, 171, 209, 171, 33,
     207, 88, 175, 70, 175, 70, 175, 70, 175, 70, 175, 70, 175, 70, 175, 70, 175, 118, 244, 106, 71, 175, 118, 200,
     171, 217, 171, 29, 189, 218, 209, 171, 29, 189, 218, 209, 171, 29, 189, 218, 209, 171, 157, 189, 218, 217, 171, 157,
     189, 218, 41, 95, 180, 94, 237, 236, 213, 206, 94, 237, 236, 213, 206, 94, 237, 236, 213, 70, 175, 54, 122, 181,
     209, 171, 141, 94, 109, 200, 143, 160, 87, 27, 189, 218, 232, 213, 70, 175, 54, 122, 181, 217, 171, 205, 94, 109,
     246, 106, 179, 87, 155, 189, 218, 148, 255, 103, 175, 54, 123, 181, 217, 171, 205, 94, 237, 234, 213, 174, 94, 237,
     234, 213, 174, 94, 237, 234, 213, 174, 94, 237, 146, 181, 163, 87, 187, 122, 181, 171, 87, 91, 189, 218, 234, 213,
     86, 175, 182, 122, 181, 213, 171, 173, 94, 109, 245, 106, 75, 182, 181, 94, 109, 245, 106, 119, 175, 118, 247, 106,
     119, 175, 118, 247, 106, 119, 175, 118, 247, 106, 119, 175, 118, 247, 106, 183, 44, 185, 182, 229, 202, 154, 187, 203,
     158, 187, 203, 162, 187, 203, 166, 187, 203, 170, 187, 203, 174, 187, 203, 178, 187, 203, 182, 187, 203, 186, 187, 75,
     63, 101, 130, 244, 51, 40, 152, 20, 140, 10, 102, 5, 195, 130, 105, 193, 184, 32, 94, 136, 128, 33, 34, 134,
     8, 25, 34, 102, 136, 160, 33, 162, 134, 8, 27, 34, 110, 136, 192, 33, 34, 135, 8, 29, 34, 118, 136, 224,
     33, 162, 135, 8, 31, 34, 126, 136, 0, 34, 34, 136, 8, 33, 34, 134, 136, 32, 34, 162, 136, 8, 35, 34,
     142, 136, 64, 34, 34, 137, 8, 37, 34, 150, 136, 96, 34, 162, 137, 8, 39, 34, 158, 136, 128, 34, 34, 138,
     8, 41, 34, 166, 136, 160, 34, 162, 138, 8, 43, 34, 174, 136, 192, 34, 34, 139, 8, 45, 34, 182, 136, 224,
     34, 162, 139, 8, 47, 34, 190, 136, 0, 35, 34, 140, 8, 49, 34, 198, 136, 32, 35, 162, 140, 8, 51, 34,
     206, 136, 64, 35, 34, 141, 8, 53, 34, 214, 136, 96, 35, 162, 141, 8, 55, 34, 222, 136, 128, 35, 34, 142,
     8, 57, 34, 230, 136, 160, 35, 162, 142, 8, 59, 34, 238, 136, 192, 35, 34, 143, 8, 61, 34, 246, 136, 224,
     35, 162, 143, 8, 63, 34, 254, 64, 252, 129, 248, 3, 241, 7, 226, 15, 196, 31, 136, 63, 16, 127, 32, 254,
     64, 252, 129, 248, 3, 241, 7, 226, 15, 196, 31, 136, 63, 16, 127, 32, 254, 64, 252, 129, 248, 3, 241, 7,
     118, 175, 176, 131, 133, 94, 44, 164, 159, 221, 44, 236, 104, 97, 87, 11, 59, 91, 216, 221, 194, 14, 23, 226,
     15, 196, 31, 136, 63, 16, 127, 32, 254, 64, 252, 129, 248, 3, 241, 7, 226, 15, 196, 31, 136, 63, 16, 127,
     32, 254, 64, 252, 129, 248, 3, 241, 7, 226, 15, 196, 31, 136, 63, 16, 127, 32, 254, 64, 252, 129, 248, 3,
     241, 7, 226, 15, 196, 31, 136, 63, 16, 127, 32, 254, 64, 252, 129, 248, 3, 241, 7, 226, 15, 196, 31, 136,
     63, 16, 127, 32, 254, 64, 252, 129, 248, 3, 241, 7, 226, 15, 196, 31, 136, 63, 16, 127, 32, 254, 64, 252,
     129, 248, 3, 241, 7, 226, 15, 196, 31, 136, 63, 16, 127, 32, 254, 64, 252, 129, 248, 3, 241, 7, 226, 15,
     196, 31, 136, 63, 16, 127, 32, 254, 64, 252, 129, 248, 3, 241, 7, 226, 15, 196, 31, 136, 63, 16, 127, 32,
     254, 64, 252, 193, 255, 253, 241, 13, 80, 75, 3, 4, 10, 0, 0, 0, 0, 0, 7, 153, 51, 93, 72, 201,
     17, 72, 10, 0, 0, 0, 10, 0, 0, 0, 9, 0, 0, 0, 116, 111, 112, 47, 97, 46, 116, 120, 116, 104,
     101, 108, 108, 111, 32, 122, 105, 112, 10, 80, 75, 1, 2, 30, 3, 10, 0, 0, 0, 0, 0, 7, 153, 51,
     93, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16,
     0, 237, 65, 0, 0, 0, 0, 116, 111, 112, 47, 80, 75, 1, 2, 30, 3, 10, 0, 0, 0, 0, 0, 7,
     153, 51, 93, 16, 169, 201, 169, 19, 0, 0, 0, 19, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 1,
     0, 0, 0, 237, 129, 34, 0, 0, 0, 116, 111, 112, 47, 114, 117, 110, 46, 115, 104, 80, 75, 1, 2, 30,
     3, 10, 0, 0, 0, 0, 0, 7, 153, 51, 93, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 237, 65, 93, 0, 0, 0, 116, 111, 112, 47, 115, 117, 98,
     47, 80, 75, 1, 2, 30, 3, 20, 0, 0, 0, 8, 0, 7, 153, 51, 93, 228, 61, 90, 63, 232, 2, 0,
     0, 18, 37, 0, 0, 15, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 164, 129, 131, 0, 0, 0, 116,
     111, 112, 47, 115, 117, 98, 47, 98, 105, 103, 46, 116, 120, 116, 80, 75, 1, 2, 30, 3, 10, 0, 0, 0,
     0, 0, 7, 153, 51, 93, 72, 201, 17, 72, 10, 0, 0, 0, 10, 0, 0, 0, 9, 0, 0, 0, 0, 0,
     0, 0, 1, 0, 0, 0, 164, 129, 152, 3, 0, 0, 116, 111, 112, 47, 97, 46, 116, 120, 116, 80, 75, 5,
     6, 0, 0, 0, 0, 5, 0, 5, 0, 20, 1, 0, 0, 201, 3, 0, 0, 0, 0,
    ]

fn write_bytes(path: &str, bytes: &Vec[u8]):
    let cpath = path.to_cstring().unwrap()
    let stream = fopen(cpath.ptr as *const i8, c"wb".ptr)
    assert(stream != null)
    assert(fwrite(bytes.ptr as *const c_void, 1, bytes.len() as u64, stream) == bytes.len() as u64)
    assert(fclose(stream) == 0)

fn text_of(bytes: &Vec[u8]) -> str:
    var out = ""
    for i in 0..bytes.len() as i32: out = out ++ with_str_from_bytes(&raw const bytes[i] as *const u8, 1)
    out

// Every occurrence of `from` becomes `to` (same length): the local header
// and the central directory both carry the name, and no checksum covers it.
fn rename_entry(bytes: &Vec[u8], from: &str, to: &str) -> Vec[u8]:
    assert(from.len() == to.len())
    var out: Vec[u8] = Vec.new()
    for i in 0..bytes.len() as i32: out.push(bytes[i])
    var at = 0
    while at + from.len() as i32 <= out.len() as i32:
        var same = true
        for k in 0..from.len() as i32:
            if out[at + k] != from[k]: same = false
        if same:
            for k in 0..to.len() as i32: out[at + k] = to[k]
        at = at + 1
    out

fn main:
    let case_dir = p7_prepare_case("zip_reads_info_zip", "zipcase")
    let archive_path = p7_join(case_dir, "t.zip")
    write_bytes(archive_path, &fixture())

    let archive = ZipArchive.open(archive_path).unwrap()
    let entries = archive.entries().unwrap()
    assert(entries.len() == 5)
    var names = ""
    for entry in entries: names = names ++ entry.name ++ f":{entry.size}:{entry.is_dir} "
    assert(names.contains("top/:0:true "))
    assert(names.contains("top/a.txt:10:false "))
    assert(names.contains("top/sub/:0:true "))
    assert(names.contains("top/sub/big.txt:9490:false "))
    assert(names.contains("top/run.sh:19:false "))
    for entry in entries:
        if entry.name == "top/run.sh": assert(entry.mode == 0o755)
        if entry.name == "top/a.txt": assert(entry.mode == 0o644)

    assert(text_of(&archive.read("top/a.txt").unwrap()) == "hello zip\n")
    let big = text_of(&archive.read("top/sub/big.txt").unwrap())
    assert(big.len() == 9490)
    assert(big.starts_with("line 0 of a compressible file\n"))
    assert(big.ends_with("line 299 of a compressible file\n"))
    match archive.read("top/missing.txt"):
        Ok(_) => assert(false)
        Err(e) => assert(e.message.contains("top/missing.txt"))

    let dest = p7_join(case_dir, "extracted")
    assert(extract(archive_path, dest).unwrap() == 3)
    assert(read_file(p7_join(dest, "top/a.txt")).unwrap() == "hello zip\n")
    assert(read_file(p7_join(dest, "top/sub/big.txt")).unwrap() == big)
    assert(read_file(p7_join(dest, "top/run.sh")).unwrap() == "#!/bin/sh\necho ran\n")

    // An entry that would land outside the destination fails the extraction
    // and writes nothing there.
    let escaping_path = p7_join(case_dir, "escaping.zip")
    write_bytes(escaping_path, &rename_entry(&fixture(), "top/a.txt", "../../a.t"))
    match extract(escaping_path, p7_join(case_dir, "jail/inner")):
        Ok(_) => assert(false)
        Err(e) => assert(e.message.contains("escapes the destination"))
    assert(not file_exists(p7_join(case_dir, "a.t")))

    // A corrupted byte inside the deflated member fails its CRC or its
    // inflate, never a silent short read.
    var damaged = fixture()
    damaged[700] = damaged[700] ^ 0x55
    let damaged_path = p7_join(case_dir, "damaged.zip")
    write_bytes(damaged_path, &damaged)
    let damaged_archive = ZipArchive.open(damaged_path).unwrap()
    match damaged_archive.read("top/sub/big.txt"):
        Ok(_) => assert(false)
        Err(_) => print("ok")
