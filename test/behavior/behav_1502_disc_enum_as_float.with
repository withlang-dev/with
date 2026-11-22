//! expect-stdout: 200
//! expect-stdout: 1
//! expect-stdout: 201

// #1502 (§4.4a): `Kind.Hi as f64` extracts the discriminant and widens it;
// it passed Sema and failed the MIR validator ("unsupported cast").

enum Kind: u8:
    Red = 1
    Hi = 200

fn main:
    let f = Kind.Hi as f64
    print(f)
    let g: f32 = Kind.Red as f32
    print(g)
    print(f + g)
