# 21. Borrow Checker Rules

The borrow checker is primarily local, but function boundaries do
participate in lifetime reasoning through inferred effect summaries.
In particular, when a function returns a view derived from one or more
parameters, the compiler tracks which parameters may be origins of that
returned view and enforces that those origins outlive all uses of the
result.

### 21.1 Rules

At every program point, the following must hold:

1. **View-liveness rule.** Active shared borrows (`&T`) of a place
   are invalidated when the place is mutated. Mutation includes
   assignment, calling a `mut self` method, and modification through
   `with` or `IndexPlace`. The compiler rejects code that uses a
   borrow after the borrowed place has been mutated.

2. **Move validity.** A move of a place must not occur while any
   borrow of that place (or an overlapping place) is active.

3. **Use-after-move.** A binding that has been moved from must not
   be used.

4. **NLL scoping.** A borrow is active from its creation to the
   last program point that uses the borrowed reference. Not to the
   end of the enclosing block.

5. **Disjoint field access.** Two borrows of field paths that
   diverge at any field access are non-overlapping and may coexist.
   Array/slice indices are conservatively treated as overlapping.

6. **Returned-view origin tracking.** A returned view's origins are every parameter it derives from and every global the body returns a view of, directly or through a callee's returned view. A signature names a global origin with `from G`, beside `from p`. A declared origin the body does not derive the view from is an error, never a silent widening. A global origin is part of the function's interface (D79): a bundle interface records it by an identity that does not export the global, and every exported function that writes that global declares it in its writes clause, whether or not the global is exported. Each origin in a `from` clause names a parameter, `self`, or a global, whole: `a.b` is a module-qualified global, never a field of parameter `a`. On a return type that holds several views, the clause lists the union of the origins of every view in it. Without a clause, a returned view's origins are inferred from the body; at a bundle boundary an exported function whose returned view has a global origin must state the clause, an absent clause means the §21.1 elision (the receiver, else the single borrowed parameter), and `from static` states a view of static data.
   At the call site, the result is tied to
   the intersection of those origin lifetimes. If any possible origin
   dies before the view's last use, the program is rejected.

   Raw pointers are not views for this rule. A `*const T` or `*mut T`
   value is an address, not a borrow; validity is asserted when it is
   dereferenced, converted to a safe reference/slice/view inside
   `unsafe`, or relied on across an `unsafe fn` boundary (§16.11).

   ```
   fn longest(a: &String, b: &String) -> &str:
       if a.len() > b.len():
           a.as_str()
       else:
           b.as_str()

   let s1 = String.from("hello")
   let view: &str
   {
       let s2 = String.from("world")
       view = longest(s1, s2)
   }
   print(view) // ERROR: view may originate from s2
   ```

7. **Implicit drop is a use.** When a variable implementing `Drop`
   goes out of scope, its implicit destructor call is treated as a
   **use** of that variable for borrow-checking purposes. This
   prevents use-after-free in cases like:

   ```
   var v: Vec[&i32] = Vec.new()
   var x = 5
   v.push(&x)
   // End of scope: x drops first, then v drops.
   // v.drop() accesses &x, but x is already freed!
   // Rejected: v's implicit drop uses &x after x is destroyed.
   ```

   The compiler inserts implicit drop points at scope exit in
   reverse declaration order. Each drop point is a "use" of the
   variable being dropped, extending the borrow lifetime through
   the destructor.

8. **Mutation composability.** Mutation through `mut self` receivers
   does not require reborrowing — the receiver is the caller's place.
   Each `mut self` call mutates that place and leaves it valid for
   subsequent calls. In a pipeline, a Unit-returning `mut fn` stage
   continues with that place; a non-Unit stage continues with its return
   value (§9.6, D21).

9. **Move-state join.** At a control-flow merge, a place is moved if it
   is moved on any predecessor path that reaches the merge without
   diverging. Paths that diverge — `return`, `break`, `continue`, or a
   call that never returns — contribute no move-state to the merge. A
   place that is moved on some reaching paths and live on others is
   treated as **moved** for use-checking (§2.2): it may not be used
   until reinitialized on all paths. This move-state drives the
   *diagnostic* (use-after-move) and the *optimizer* (it elides the
   generation check wherever ownership is statically settled, §2.5.2); it
   is not what makes the destructor safe. The runtime generation (§2.5)
   is: where the analysis cannot settle ownership, the generation check
   stands and the destructor frees on exactly the live path and no-ops on
   the others, with no static drop-flag elaboration required.

   ```
   // moved in one branch, reinitialized in the other → still a
   // use-after-move (the first branch does not reinitialize):
   if cond: consume(v) else: v = T.new()
   use(v)               // ERROR unless reinitialized on every path

   // an arm that consumes the value and then diverges does NOT mark
   // the value moved on the fallthrough path:
   match m:
       .A => return consume(owner)   // moves owner, but exits
       _  => ()
   use(owner)                        // OK: the only arm that moved
                                     // owner left the function
   ```

10. **Transparent-carrier origin propagation.** Constructing, projecting,
    eliminating, or joining values that contain views preserves the origin
    set of every view that can flow into the result. This includes `Option`,
    `Result`, tuples, pattern bindings, `if let`, `let ... else`, `match`, `?`,
    `??`, `unwrap`, `expect`, and non-owning combinators.

    A control-flow join carries the union of the origins from all reaching
    view-producing paths. An operation ends origin propagation only when it
    actually produces an independent owned value, including contextual
    materialization of a `Copy` pointee, an explicit clone, or ownership
    transferred by a consuming collection operation such as `remove`.

    Origin tracking follows semantic values, not wrapper spellings. A view
    does not become independent merely because it passed through an enum,
    temporary, intrinsic, or compiler-generated lowering.

---
