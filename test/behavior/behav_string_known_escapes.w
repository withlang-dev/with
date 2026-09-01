//! expect-stdout: ok

// #929 companion: every escape the decoders accept still round-trips —
// the parser validator must never reject a supported spelling, in plain
// strings and at f-string depth 0 alike.
fn main:
    let plain = "\n\t\r\0\\\"\x41"
    if plain.len() != 7:
        print("FAIL plain len")
        return
    if plain.byte_at(6) != 65 or plain.byte_at(3) != 0 or plain.byte_at(4) != 92:
        print("FAIL plain bytes")
        return
    let x = 5
    let inter = f"v={x}\t\x42"
    if inter.len() != 5 or inter.byte_at(4) != 66:
        print("FAIL fstring")
        return
    let raw = r"\u{41}\q"
    if raw.len() != 8:
        print("FAIL raw")
        return
    let braces = "\{\}\'"
    if braces.len() != 3 or braces.byte_at(0) != 123 or braces.byte_at(1) != 125 or braces.byte_at(2) != 39:
        print("FAIL braces")
        return
    let fbrace = f"\{{x}\}"
    if fbrace != "{5}":
        print("FAIL fstring brace")
        return
    let fslash = f"\\{{x}}"
    if fslash != "\\{x}":
        print("FAIL fstring escaped backslash before brace")
        return
    print("ok")
