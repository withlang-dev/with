//! expect-check-fail: variant 'Blue' does not belong to enum 'ImportBadColor'

enum ImportBadColor { Red | Green }
use ImportBadColor.{Blue}

fn bad_import_unknown_variant:
    assert(true)
