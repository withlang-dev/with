fn direct_ret(s: str) -> i32:
    s.len

fn main():
    print(f"direct: {"abc".len}\n")
    print(f"via fn: {direct_ret("abc")}\n")
    let t = direct_ret("abc")
    print(f"via let: {t}\n")
