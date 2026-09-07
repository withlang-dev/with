fn main:
    match "hi".to_cstring():
        Ok(c) => print(f"cok={c.len()}")
        Err(x) => print("cstr-unexpected-err")
    match "a\x00b".to_cstring():
        Ok(c2) => print("cstr-SILENT-TRUNC")
        Err(x2) => print("cstr-loud-InteriorNul")
