# D229 — A pipeline over a field as a function's last line is refused

**Laws:** D32 (a field never moves out implicitly), D21 (a pipeline of Unit
`mut fn` stages carries its receiver place), D43 (an unannotated function
infers its return from its tail).

**Date:** 2026-11-22. **Status:** ruled by Eric; implemented. No spec words:
§2.2 already states the rule.

**Context.** #3467. In a function with no return type,

```
fn run(s: *mut i32):
    let h = H { items: List.new() }
    h.items |> push(W { slot: s }) |> push(W { slot: s })
```

the last line is the function's value, and by D21 that value is the place
`h.items`. The program compiled: `run` returned the field after `h` was
dropped, an empty list whose elements were already destroyed. Only the
ownership validator said so.

**Ruling.** Refuse it. `fn f(): h.items` is refused, and a pipeline whose
value is that same field gets the same answer. The help leads with `-> Unit`,
which is almost always what was meant, and names `move h.items` second.

**Alternative weighed.** Read a tail pipeline over a field as a statement,
so the function returns Unit. It would make a tail pipeline a statement over
a field and a value over a local: a reader would have to know which root
they are looking at.

**Tests.** The program is kept as `err_tail_pipeline_moves_field`, and with
`-> Unit` as `da_vecdrop_field_push_chain_tail`, which the validator lane now
judges like every other test.
