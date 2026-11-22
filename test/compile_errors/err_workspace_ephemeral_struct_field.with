//! expect-error: ephemeral type 'Workspace' cannot be stored in non-ephemeral struct

use std.build

type LeakedWorkspace {
    workspace: Workspace,
}

fn main:
    print("unreachable")
