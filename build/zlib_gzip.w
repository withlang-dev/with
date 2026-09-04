use std.fs
use std.process
use std.string
use std.zlib

fn bytes_from_str(data: &str) -> Vec[u8]:
    let out: Vec[u8] = Vec.new()
    var i: i64 = 0
    while i < data.len():
        out.push(data[i])
        i = i + 1
    out

fn bytes_to_str(data: Vec[u8]) -> str: StringBuilder { bytes: data }.to_str()

fn main -> i32:
    let argv = args()
    if argv.len() < 3:
        print("usage: zlib_gzip <input.tar> <output.tar.gz>")
        return 2
    let input = match read_file(argv.get(1)):
        Ok(text) => text
        Err(err) => {
            print("could not read input tar: " ++ err.message())
            return 1
        }
    if input.len() == 0:
        print("input tar is empty")
        return 1
    let input_bytes = bytes_from_str(input)
    match compress_gzip(&input_bytes):
        Ok(gzip_bytes) => {
            if write_file(argv.get(2), bytes_to_str(gzip_bytes)) != 0:
                print("could not write gzip output")
                return 1
        }
        Err(err) => {
            print(err.message)
            return 1
        }
    0
