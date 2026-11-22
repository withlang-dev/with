//! expect-stdout: ok

use std.regex
use std.regex.Captures
use std.zlib

fn test_regex_compile_match_find:
    let re = Regex.compile("^(\\w+)\\s+(\\w+)$").unwrap()
    assert(re.is_match("hello world"))
    assert(not re.is_match("hello"))

    let digits = Regex.compile("\\d+").unwrap()
    let first = digits.find("abc123def").unwrap()
    assert(first.text == "123")
    assert(first.start == 3)
    assert(first.end == 6)

    let second = digits.find_at("abc123def45", 7).unwrap()
    assert(second.text == "45")
    assert(second.start == 9)
    assert(second.end == 11)

    let all = digits.find_all("a1b22c333")
    assert(all.len() == 3)
    assert(all[0].text == "1")
    assert(all[1].text == "22")
    assert(all[2].text == "333")

fn test_regex_captures:
    let re = Regex.compile("^(?<key>\\w+)=(?<value>\\w+)$").unwrap()
    let caps = re.captures("name=with").unwrap()
    assert(caps.len() == 3)
    assert(caps.get(0).unwrap().text == "name=with")
    assert(caps.get(1).unwrap().text == "name")
    assert(caps.get(2).unwrap().text == "with")
    assert(caps.name("key").unwrap().text == "name")
    assert(caps.name("value").unwrap().text == "with")
    assert(re.num_captures() == 2)
    assert(re.capture_index("key").unwrap() == 1)
    assert(re.capture_index("value").unwrap() == 2)

fn bracket_pair(caps: &Captures) -> str:
    "[" ++ caps.name("key").unwrap().text ++ ":" ++ caps.get(2).unwrap().text ++ "]"

fn test_regex_replace_split:
    let digits = Regex.compile("\\d+").unwrap()
    assert(digits.replace("a1b22c", "#") == "a#b22c")
    assert(digits.replace_all("a1b22c", "#") == "a#b#c")

    let global_digits = Regex.compile_flags("\\d+", "g").unwrap()
    assert(global_digits.replace("a1b22c", "#") == "a#b#c")

    let pair = Regex.compile("(?<key>\\w+)=(\\w+)").unwrap()
    assert(pair.replace("x=one y=two", "${key}:$2") == "x:one y=two")
    assert(pair.replace_all("x=one y=two", "$1:$$:$2") == "x:$:one y:$:two")

    let bracketed = pair.replace_fn("x=one y=two", bracket_pair)
    assert(bracketed == "[x:one] y=two")

    let all_bracketed = pair.replace_all_fn("x=one y=two", bracket_pair)
    assert(all_bracketed == "[x:one] [y:two]")

    let zero = Regex.compile("x").unwrap().replace("x", "\x00")
    assert(zero.len() == 1)
    assert(zero.byte_at(0) == 0)

    let parts = digits.split("a1b22c")
    assert(parts.len() == 3)
    assert(parts[0] == "a")
    assert(parts[1] == "b")
    assert(parts[2] == "c")

    let limited = digits.splitn("a1b22c333d", 2)
    assert(limited.len() == 2)
    assert(limited[0] == "a")
    assert(limited[1] == "b22c333d")

fn bytes_from_str(s: str) -> List[u8]:
    let out: List[u8] = List.new()
    var i: i64 = 0
    while i < s.len():
        out.push(s.byte_at(i) as u8)
        i = i + 1
    out

fn assert_bytes_eq(actual: &List[u8], expected: &List[u8]):
    assert(actual.len() == expected.len())
    var i: i64 = 0
    while i < expected.len():
        assert(actual[i] == expected[i])
        i = i + 1

fn test_zlib_round_trip:
    let original = bytes_from_str("hello hello hello hello hello with zlib")
    let compressed = compress(&original).unwrap()
    assert(compressed.len() > 0)
    assert(compressed.len() < original.len())
    let restored = decompress(&compressed).unwrap()
    assert_bytes_eq(&restored, &original)

    let gz_original = bytes_from_str("gzip gzip gzip gzip gzip with zlib")
    let gz_compressed = compress_gzip(&gz_original).unwrap()
    assert(gz_compressed.len() > 10)
    assert(gz_compressed[0] == 31 as u8)
    assert(gz_compressed[1] == 139 as u8)
    let gz_restored = decompress_gzip(&gz_compressed).unwrap()
    assert_bytes_eq(&gz_restored, &gz_original)

fn main:
    test_regex_compile_match_find()
    test_regex_captures()
    test_regex_replace_split()
    test_zlib_round_trip()
    print("ok")
