//! expect-error: file not found

use c_import("<with_missing_header_for_issue_288.h>")

fn main:
    print("unreachable")
