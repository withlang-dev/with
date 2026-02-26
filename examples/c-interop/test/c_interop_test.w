// Tests for the C interop example

extern fn strlen(s: *const i8) -> i64
extern fn strcmp(a: *const i8, b: *const i8) -> i32

type SafeStr = {
    data: str,
    len: i32,
}

extend SafeStr =
    fn new(s: str) -> SafeStr:
        SafeStr { data: s, len: s.len as i32 }

    fn get_len(self: SafeStr) -> i32:
        self.len

type Entry = {
    key: i32,
    value: i32,
    active: bool,
}

fn make_entry(key: i32, value: i32) -> Entry:
    Entry { key: key, value: value, active: true }

fn sum_entries(entries: [5]Entry) -> i32:
    var sum = 0
    for i in 0..5:
        sum = sum + entries[i].value
    sum

fn count_active(entries: [5]Entry) -> i32:
    var n = 0
    for i in 0..5:
        if entries[i].active then n = n + 1 else n = n
    n

fn find_value(entries: [5]Entry, key: i32) -> i32:
    var result = 0
    for i in 0..5:
        if entries[i].key == key then result = entries[i].value else result = result
    result

fn main -> i32:
    // Test strlen via C interop
    assert(strlen("hello") == 5)
    assert(strlen("") == 0)
    assert(strlen("With Language") == 13)

    // Test strcmp via C interop
    assert(strcmp("abc", "abc") == 0)
    assert(strcmp("abc", "def") < 0)
    assert(strcmp("def", "abc") > 0)

    // Test SafeStr wrapper
    let s1 = SafeStr.new("Hello World")
    assert(s1.len == 11)
    assert(s1.get_len() == 11)

    let s2 = SafeStr.new("")
    assert(s2.len == 0)

    let s3 = SafeStr.new("With")
    assert(s3.get_len() == 4)

    // Test combined lengths
    let total = s1.get_len() + s3.get_len()
    assert(total == 15)

    // Test Entry and make_entry
    let e = make_entry(42, 100)
    assert(e.key == 42)
    assert(e.value == 100)
    assert(e.active == true)

    // Test sum_entries
    let entries: [5]Entry = [
        make_entry(1, 100),
        make_entry(2, 200),
        make_entry(3, 300),
        make_entry(4, 400),
        make_entry(5, 500),
    ]
    assert(sum_entries(entries) == 1500)

    // Test count_active
    assert(count_active(entries) == 5)

    // Test find_value
    assert(find_value(entries, 1) == 100)
    assert(find_value(entries, 3) == 300)
    assert(find_value(entries, 5) == 500)

    // Test type casting in SafeStr
    let s4 = SafeStr.new("twelve chars")
    assert(s4.len == 12)

    println("c-interop: all tests passed")
