extern fn print(s: str) -> void
extern fn int_to_string(n: i32) -> str

@[flags]
type Perms: i32 = Read | Write | Execute

fn main:
    let rw = Perms.Read + Perms.Write
    assert(rw == 3)
    let rwx = Perms.Read + Perms.Write + Perms.Execute
    assert(rwx == 7)
    // Individual values are powers of 2
    assert(Perms.Read == 1)
    assert(Perms.Write == 2)
    assert(Perms.Execute == 4)
    print("ok")
