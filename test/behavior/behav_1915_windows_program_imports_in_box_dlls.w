//! only-on: windows
//! expect-stdout: printf from the SDK's UCRT 42
//! expect-stdout: ok

// #1915: a With program on Windows links nothing but the LLVM SDK and runs
// against nothing but DLLs Windows ships in the box. It linked Visual
// Studio's DLL runtime (msvcrt.lib/vcruntime.lib/msvcprt.lib), so every
// program imported VCRUNTIME140.dll — a redistributable, absent from a clean
// Windows — and the link needed Visual Studio and a Windows Kit. The program
// reads its own PE import table and checks each DLL it names is in the box.
// It also calls through a c_import of the SDK's libc headers: printf (the
// UCRT's, through mingw-w64's out-of-line wrapper) and GetCurrentProcessId.
use std.fs
use std.process
use c_import("stdio.h")
use c_import("windows.h", only: ["GetCurrentProcessId"])

fn u16_at(b: &str, at: i64) -> i64: b[at] as i64 | (b[at + 1] as i64 << 8)

fn u32_at(b: &str, at: i64) -> i64: u16_at(b, at) | (u16_at(b, at + 2) << 16)

// The file offset of an RVA, through the section table; -1 when no section
// holds it.
fn file_offset(b: &str, sections: i64, count: i64, rva: i64) -> i64:
    for i in 0..count:
        let s = sections + i * 40
        let va = u32_at(b, s + 12)
        let size = u32_at(b, s + 16)
        if rva >= va and rva < va + size:
            return rva - va + u32_at(b, s + 20)
    -1

fn c_string(b: &str, at: i64) -> str:
    var end = at
    while b[end] != 0:
        end += 1
    b.slice(at, end)

fn in_box(dll: &str) -> bool:
    if dll.starts_with("api-ms-win-crt-") or dll.starts_with("api-ms-win-core-"):
        return true
    let names = ["kernel32.dll", "ntdll.dll", "ucrtbase.dll", "advapi32.dll", "bcrypt.dll", "ws2_32.dll", "dbghelp.dll", "shell32.dll", "user32.dll", "ole32.dll", "oleaut32.dll", "version.dll", "psapi.dll"]
    for n in names:
        if dll == n:
            return true
    false

fn main:
    let pid = GetCurrentProcessId()
    assert(pid != 0)
    let _ = unsafe { printf(c"printf from the SDK's UCRT %d\n".ptr, 42) }
    let _ = unsafe { fflush(null) }
    let image = read_file(args()[0]) ?? panic("cannot read " ++ args()[0])
    let pe = u32_at(image, 0x3c)
    assert(u32_at(image, pe) == 0x4550)
    let count = u16_at(image, pe + 6)
    let optional = pe + 24
    let sections = optional + u16_at(image, pe + 20)
    assert(u16_at(image, optional) == 0x20b)
    let import_rva = u32_at(image, optional + 112 + 8)
    var at = file_offset(image, sections, count, import_rva)
    assert(at > 0)
    var bad = 0
    var total = 0
    while u32_at(image, at + 12) != 0:
        let dll = c_string(image, file_offset(image, sections, count, u32_at(image, at + 12))).to_lower()
        total += 1
        if not in_box(dll):
            print("imports a DLL Windows does not ship: " ++ dll)
            bad += 1
        at += 20
    assert(total > 0)
    if bad == 0:
        print("ok")
