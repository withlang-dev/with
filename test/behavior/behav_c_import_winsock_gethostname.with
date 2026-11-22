//! only-on: windows
//! expect-stdout: ok

// A program that calls Winsock's gethostname reaches Winsock's. The Windows
// runtime backend defined the C symbol `gethostname` itself, for
// std.os.hostname(); ws2_32.lib is on every Windows link line, so a call
// from With bound to the runtime's function (0 and the computer name, even
// before WSAStartup), and a C library that calls Winsock's through
// __imp_gethostname (libcurl) failed to link: "duplicate symbol: gethostname
// ... defined at ws2_32.lib(WS2_32.dll)".

use std.os
use c_import("int gethostname(char *name, int namelen);\nint WSAGetLastError(void);\nint WSAStartup(unsigned short version, void *data);\nint WSACleanup(void);\n", link: "ws2_32")

fn main:
    var name: [256]u8 = [0 as u8; 256]
    let name_ptr = &raw mut name as *mut [256]u8 as *mut c_char
    // Before WSAStartup Winsock refuses: SOCKET_ERROR, WSANOTINITIALISED.
    assert(unsafe { gethostname(name_ptr, 256) } == -1)
    assert(WSAGetLastError() == 10093)
    var wsa: [512]u8 = [0 as u8; 512]
    assert(unsafe { WSAStartup(0x0202 as u16, &raw mut wsa as *mut [512]u8 as *mut c_void) } == 0)
    assert(unsafe { gethostname(name_ptr, 256) } == 0)
    assert(name[0] != 0)
    WSACleanup()
    // The runtime's own host name is still there for std.os.
    assert(hostname().len() > 0)
    print("ok")
