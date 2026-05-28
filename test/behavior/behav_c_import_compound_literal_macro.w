//! expect-stdout: ok

use c_import("typedef struct Color288 { unsigned char r; unsigned char g; unsigned char b; unsigned char a; } Color288;\n#define CLITERAL(type) (type)\n#define LIGHTGRAY288 CLITERAL(Color288){ 200, 200, 200, 255 }\n#define RAYWHITE288 CLITERAL(Color288){ 245, 245, 245, 255 }\n")

fn main:
    assert(LIGHTGRAY288.r == 200)
    assert(LIGHTGRAY288.a == 255)
    assert(RAYWHITE288.r == 245)
    print("ok")
