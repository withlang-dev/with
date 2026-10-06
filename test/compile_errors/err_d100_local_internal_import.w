//! expect-check-fail: module 'gadget.internal.core' is internal to

// D100 (§18.3): lib/gadget/internal/core.w is importable only by modules
// inside lib/gadget (gadget.api imports it, behav_d100_internal_from_parent);
// this file is outside that tree.
use gadget.internal.core

fn main:
    print(f"{core_value()}")
