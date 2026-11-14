//! expect-stdout: 43 42 42 42 1000 -42
//! expect-stdout: 3.14 1000 inf -inf true
//! expect-stdout: 255 18446744073709551615 -128
//! expect-stdout: 44 3 1 4294967295
//! expect-stdout: 7 12
// §15.5 (D204): text converts to a type that implements `Parse` with `as`;
// the result is the type. The cast and `text.parse()` are one conversion.
// Every other cast is unchanged (§4.2.6): the fourth line.
type Celsius { tenths: i32 }

impl Parse for Celsius:
    fn parse_text(text: &str) -> Option[Celsius]:
        let whole: i32 = text.parse()?
        Celsius { tenths: whole * 10 }

fn double(text: &str) -> i32: (text as i32) * 2

fn main:
    let line = "42"
    print(f"{(line as i32) + 1} {"0x2A" as i32} {"0b101010" as i32} {"0o52" as i32} {"1_000" as i32} {"-42" as i64}")
    let nan = "NaN" as f64
    print(f"{"3.14" as f64} {"1e3" as f64} {"Infinity" as f64} {"-inf" as f32} {nan != nan}")
    print(f"{"255" as u8} {"18446744073709551615" as u64} {"-128" as i8}")
    let v = 300
    print(f"{v as u8} {3.9 as i32} {true as i32} {-1 as u32}")
    let c = "7" as Celsius
    print(f"{c.tenths / 10} {double("6")}")
