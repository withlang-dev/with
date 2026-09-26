//! expect-stdout: 85 255 240 95
//! expect-stdout: 170 164 167

// #1477: an unsuffixed literal beside a Copy view of an integer takes the
// pointee's type for `^`, `&` and `|` too; a Vec[u8] element (`v[i]` is
// `&u8`, D27) and a `&u8` field view both count. The literal fell to i32,
// so the mixed-signedness check rejected `v[i] ^ 0x55`.

type Flags { bits: u8 }

fn field_ops(f: &Flags) -> str:
    let x = f.bits ^ 0x0F
    let a = f.bits & 0xFE
    let o = f.bits | 0x03
    f"{x} {a} {o}"

fn main:
    let v: Vec[u8] = Vec.new()
    v.push(0)
    v.push(255)
    v[0] = v[0] ^ 0x55
    let masked = v[1] & 0xF0
    let both = v[0] | 0x0F
    print(f"{v[0]} {v[1]} {masked} {both}")
    let f = Flags { bits: 165 }
    print(field_ops(f))
