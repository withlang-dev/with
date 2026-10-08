# D110 — A parameter's mode is what the callee does with it

**Date:** 2026-10-08. **Status:** ruled (Eric Hartford).

**Ruling (Eric, verbatim).** "A parameter's mode is what the callee does with
it. If the callee stores the argument, ownership transfers. If it only reads
it, the argument is observed. This is a reading of the function, not a design
choice. get, contains, remove take their key as a probe and observe it.
insert stores its key and takes it. increment/decrement observe the probe and
take their own copy of the key only on the insert path."

"Parameter modes come from signatures, once. Builtin container methods get
declared signatures (fn remove(key: &K) -> Option[V]), and Sema's move
checking, MIR lowering and drop emission all read the mode from the
signature. … A builtin must not have a second ownership system."

**Process rule (Eric).** Before bringing an ownership question, state what
the callee does with the argument and whether the type has identity (D111).
If those two facts decide it, it is not a ruling: do the work.

**Context.** #2265 found `HashMap.remove` consuming its key, so a str key was
move-blanked after the call; the fix made that a "use of moved value", and the
question whether `remove` should observe its key went to Eric. It should not
have: the callee only reads the probe.

**Consequences.** `HashMap.get/contains/remove(key: &K)`,
`HashSet.contains/remove(value: &T)`, `BTreeMap.remove(key: &K)`,
`BTreeSet.remove(value: &T)`, `HashMap.increment/decrement(key: &K)`;
`insert` takes `K`. The hand lists that gave builtins a second ownership
system (`method_arg_consumes_key` in SemaCheck.w, the intrinsic observer test
in MirLower.w, the per-intrinsic probe drops in CodegenDispatch.w) are
deleted; every stage reads the declared signature. Specification §3.8 already
says "the parameter's declared type states the mode"; the builtins were
non-compliant.

**Reopen if:** never as a design question; a callee whose storage of an
argument is conditional states that in its signature like any other.
