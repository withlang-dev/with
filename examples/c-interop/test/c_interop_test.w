// Tests for the C interop example

use test.testing

extern fn strlen(s: *const i8) -> i64
extern fn strcmp(a: *const i8, b: *const i8) -> i32

type SafeStr = {
    data: str,
    len: i32,
}

extend SafeStr:
    fn new(s: str) -> SafeStr: SafeStr { data: s, len: s.len as i32 }

    fn get_len(self: SafeStr) -> i32: self.len

type Entry = {
    key: i32,
    value: i32,
    active: bool,
}

fn make_entry(key: i32, value: i32) -> Entry: Entry { key, value, active: true }

fn sum_entries(entries: [5]Entry) -> i32:
    var sum = 0
    for i in 0..5:
        sum = sum + entries[i].value
    sum

fn count_active(entries: [5]Entry) -> i32:
    var n = 0
    for i in 0..5:
        if entries[i].active:
            n = n + 1
    n

fn find_value(entries: [5]Entry, key: i32) -> i32:
    var result = 0
    for i in 0..5:
        if entries[i].key == key:
            result = entries[i].value
    result

@[test]
fn test_c_interop_example:
    // Test strlen via C interop
    assert_true(strlen("hello") == 5)
    assert_true(strlen("") == 0)
    assert_true(strlen("With Language") == 13)

    // Test strcmp via C interop
    assert_true(strcmp("abc", "abc") == 0)
    assert_true(strcmp("abc", "def") < 0)
    assert_true(strcmp("def", "abc") > 0)

    // Test SafeStr wrapper
    let s1 = SafeStr.new("Hello World")
    assert_true(s1.len == 11)
    assert_true(s1.get_len() == 11)

    let s2 = SafeStr.new("")
    assert_true(s2.len == 0)

    let s3 = SafeStr.new("With")
    assert_true(s3.get_len() == 4)

    // Test combined lengths
    let total = s1.get_len() + s3.get_len()
    assert_true(total == 15)

    // Test Entry and make_entry
    let e = make_entry(42, 100)
    assert_true(e.key == 42)
    assert_true(e.value == 100)
    assert_true(e.active)

    // Test sum_entries
    let entries: [5]Entry = [
        make_entry(1, 100),
        make_entry(2, 200),
        make_entry(3, 300),
        make_entry(4, 400),
        make_entry(5, 500),
    ]
    assert_true(sum_entries(entries) == 1500)

    // Test count_active
    assert_true(count_active(entries) == 5)

    // Test find_value
    assert_true(find_value(entries, 1) == 100)
    assert_true(find_value(entries, 3) == 300)
    assert_true(find_value(entries, 5) == 500)

    // Test type casting in SafeStr
    let s4 = SafeStr.new("twelve chars")
    assert_true(s4.len == 12)

