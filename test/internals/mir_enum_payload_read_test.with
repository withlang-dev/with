//! expect-stdout: ok

// The typed MIR validator rejects an enum payload read whose declared type
// is not the variant's payload type. The MIR is built by hand: the source
// path that once produced it (`?` over `Result[Unit, E]`) now lowers the
// Unit payload as nothing to extract.

use MirValidationTests

fn main:
    mir_test_enum_payload_read()
    print("ok")
