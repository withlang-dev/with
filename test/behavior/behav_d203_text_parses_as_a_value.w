//! expect-stdout: ok
// §15.5 (D203): `text.parse()` is None unless the whole text is one value
// of the demanded type. An integer is With's notation, or with `base:`
// digits of that base and no prefix; floating-point text is decimal, with
// `inf`, `infinity` and `nan`. The rows are the ruling's tables.
fn int(text: &str) -> Option[i32]: text.parse()

fn hex(text: &str) -> Option[i32]: text.parse(base: 16)

fn float(text: &str) -> Option[f64]: text.parse()

fn main:
    var bad = 0
    for (text, want) in [("42", 42), ("-42", -42), ("+42", 42), ("042", 42), ("0x2A", 42), ("0X2a", 42), ("0b101010", 42), ("0B101010", 42), ("0o52", 42), ("0O52", 42), ("1_000", 1000), ("0x2_A", 42), ("-0x2A", -42), ("2147483647", 2147483647), ("-2147483648", -2147483648)]:
        if int(text) != Some(want):
            bad += 1
            print(f"int {text}: {int(text):?}")
    for text in ["", "+", "-", "2A", " 42", "42 ", "42abc", "42u8", "1__0", "_1", "1_", "0x", "0x_1", "-_1", "0x1G", "2147483648", "-2147483649", "4.5", "1e3", "٤٢"]:
        if int(text).is_some():
            bad += 1
            print(f"int {text} was accepted: {int(text):?}")
    for (text, want) in [("2A", 42), ("2a", 42), ("0b1", 177), ("-ff", -255), ("F_F", 255), ("7fffffff", 2147483647)]:
        if hex(text) != Some(want):
            bad += 1
            print(f"hex {text}: {hex(text):?}")
    for text in ["0x1", "g", "", "80000000", "f__f"]:
        if hex(text).is_some():
            bad += 1
            print(f"hex {text} was accepted: {hex(text):?}")
    let z: Option[i64] = "zz".parse(base: 36)
    let two: Option[u8] = "11111111".parse(base: 2)
    let over: Option[u8] = "100000000".parse(base: 2)
    let unsigned: Option[u32] = "-1".parse()
    let zero: Option[u32] = "-0".parse()
    let wide: Option[u128] = "340282366920938463463374607431768211455".parse()
    let wider: Option[u128] = "340282366920938463463374607431768211456".parse()
    let least: Option[i128] = "-170141183460469231731687303715884105728".parse()
    if z != Some(1295) or two != Some(255) or over.is_some() or unsigned.is_some() or zero != Some(0) or wide.is_none() or wider.is_some() or least.is_none():
        bad += 1
        print("widths and bases")
    for (text, want) in [("3.14", 3.14), ("-2.5", -2.5), ("1e3", 1000.0), ("1E-3", 0.001), (".5", 0.5), ("42", 42.0)]:
        if float(text) != Some(want):
            bad += 1
            print(f"float {text}: {float(text):?}")
    for text in ["inf", "+inf", "Infinity", "INF", "iNfInItY"]:
        if float(text) != Some(1.0 / 0.0):
            bad += 1
            print(f"float {text}: {float(text):?}")
    for text in ["-inf", "-Infinity"]:
        if float(text) != Some(-1.0 / 0.0):
            bad += 1
            print(f"float {text}: {float(text):?}")
    for text in ["nan", "NaN", "NAN"]:
        let v = float(text) ?? 0.0
        if v == v:
            bad += 1
            print(f"float {text} is not a NaN")
    for text in ["nan(payload)", "-nan", "+nan", "0x1.8p3", " 3.14", "3.14 ", "1e", "1e999", "-1e999", "infinit", "1_0.5", ""]:
        if float(text).is_some():
            bad += 1
            print(f"float {text} was accepted: {float(text):?}")
    let single: Option[f32] = "0.1".parse()
    let single_over: Option[f32] = "1e39".parse()
    let single_inf: Option[f32] = "inf".parse()
    if single != Some(0.1 as f32) or single_over.is_some() or single_inf.is_none():
        bad += 1
        print("f32")
    if bad == 0: print("ok")
