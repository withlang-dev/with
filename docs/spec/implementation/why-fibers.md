# 14.12 Why Fibers, Not State Machines?

Fibers keep async code as ordinary control flow with real stacks, so the same
ownership, borrowing, cleanup, and panic paths apply before and after
suspension.
