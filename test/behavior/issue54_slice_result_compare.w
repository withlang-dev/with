//! expect-stdout: ok

error E =
    Bad

type Group {
    inner: str,
    next: i32,
}

fn scan(text: str, start: i32) -> Result[Group, E]:
    var pos = start
    if text.slice(pos, pos + 1) != "[":
        return Err(.Bad)
    Ok(Group { inner: "", next: pos + 1 })

fn scan_opt(text: str) -> Option[i32]:
    if text.slice(0, 1) == "[":
        Some(1)
    else:
        None

fn test_slice_compare_result:
    let ok = match scan("[", 0):
        Ok(v) => v.next == 1
        Err(_) => false
    assert(ok)

fn test_slice_compare_option:
    let r = scan_opt("[")
    let val = match r:
        Some(n) => n
        None => 0
    assert(val == 1)

fn main:
    test_slice_compare_result()
    test_slice_compare_option()
    print("ok")
