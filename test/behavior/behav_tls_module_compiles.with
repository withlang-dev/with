//! skip-on: windows #800: std.tls rides std.net, which has no Windows backend
//! expect-stdout: ok
// Pin: std.tls must compile. Nothing else in the suite imports it, so a
// latent error there (e.g. the pre-#747-flip consuming tcp_connect making
// tls_connect's later hostname use a use-after-move) sat invisible until a
// user program pulled the module in. Importing it here keeps the whole
// module inside the battery's sema/codegen coverage.
use std.tls
use std.http
use std.builtins.print

fn main: print("ok")
