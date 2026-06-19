use std.fs
use std.process
use std.zlib

extern fn with_str_from_vec_u8(bytes: *const Vec[u8]) -> str

fn bytes_from_str(data: str) -> Vec[u8]:
    let out: Vec[u8] = Vec.new()
    var i: i64 = 0
    while i < data.len():
        out.push(data.byte_at(i) as u8)
        i = i + 1
    out

fn bytes_to_str(data: &Vec[u8]) -> str:
    unsafe { with_str_from_vec_u8(data) }

fn main -> i32:
    let argv = args()
    if argv.len() < 3:
        print("usage: zlib_gzip <input.tar> <output.tar.gz>")
        return 2
    let input = read_file(argv.get(1))
    if input.len() == 0:
        print("could not read input tar")
        return 1
    let input_bytes = bytes_from_str(input)
    match compress_gzip(&input_bytes):
        Ok(gzip_bytes) => {
            if write_file(argv.get(2), bytes_to_str(&gzip_bytes)) != 0:
                print("could not write gzip output")
                return 1
        }
        Err(err) => {
            print(err.message)
            return 1
        }
    0
