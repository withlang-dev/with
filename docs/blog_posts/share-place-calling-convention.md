# Share-Place: The Calling Convention That Makes With Feel Like Python and Prove Like Rust

> **Historical design post — superseded 2026-07-23.** With now makes the
> ownership contract explicit once in the signature: `&T` borrows and plain `T`
> consumes, with auto-ref preserving call-site ergonomics. This post is retained
> as design history and must not be read as current documentation. Every later
> claim that SHARE-PLACE is “current,” “canonical,” or implementation direction
> is historical and false. For D22 intersections, `docs/meetings/d22-Eric-Ruling.md` is
> canonical. `mut fn` receivers still mutate their caller's place in place.

There's a trade every systems programmer has made a thousand times without noticing, because it's baked so deep into the languages we use that it looks like the weather.

You have a value. You want to hand it to a function. And before you can even type the call, the language has already made you answer a question that has nothing to do with what you're trying to do:

*Who owns this now?*

In C you don't answer it and you pay later — with a use-after-free at 3am. In Rust you answer it constantly and loudly: `&`, `&mut`, `.clone()`, a lifetime annotation, a borrow that won't compile, a re-architecture to satisfy the checker. In Go and Java you don't answer it because the garbage collector answers it for you, at the cost of a runtime that's always awake.

With refuses the trade. You write:

```with
append_byte(buf, 42)
```

and `buf` gets the byte appended, and `buf` is still yours afterward, and there is no `&mut`, no lifetime, no clone, no ceremony — and it is exactly as safe as the Rust version that made you write all of that. This is **share-place**, and it's the calling convention at the heart of the language. It is the thing that, once you've used it, makes going back feel like wearing a suit to your own kitchen.

Here's how it works, why no other systems language does it, and why we think you're going to love it.

## The idea in one sentence

**When you pass a value to a function, the function operates on *your* copy — your actual place in memory — and you keep it.**

That's it. `f(x)` doesn't move `x`. It doesn't copy `x`. It lends the function `x`'s place for the duration of the call. If `f` reads it, it reads yours. If `f` mutates it, it mutates yours — and you see the change. When the call returns, `x` is still there, still yours, and its destructor will still run in *your* scope when *you're* done with it.

```with
type Buffer { data: Vec[u8] }

fn append_byte(b: Buffer, value: u8):
    b.data.push(value)          # mutates the caller's buffer

let buf = Buffer { data: Vec.new() }
append_byte(buf, 42)
print(buf.data.len())           # 1 — your buffer was modified
```

No `&mut b`. No `&mut buf`. The mutation reaches you because `b` *is* `buf` — an ephemeral, borrowed alias to the same place, valid for exactly the length of the call and not one instruction longer.

If you've written Python, this is the mental model you already have. `f(my_list)` can append to `my_list`, and you know it, and you reach for it when you want it and defend against it when you don't. Share-place gives you that same intuition — with one enormous difference: the compiler has *proven*, before your program ever runs, that nothing dangling, nothing aliased-and-mutated, nothing freed-and-used can happen. Python's ergonomics. Rust's guarantees. No garbage collector in sight.

## But wait — what about ownership?

Good instinct. Because sometimes a function doesn't just *use* your value — it *keeps* it. It stores it in a global, returns it, moves it into a data structure that outlives the call. That's a genuinely different thing, and it deserves to look different:

```with
fn store(b: Buffer):
    global_buffers.push(b)      # b escapes — it outlives the call

store(buf)                      # ERROR: this parameter takes ownership;
                                #        pass `move buf` or `copy buf`
store(move buf)                 # OK — buf is transferred; you can't use it after
store(copy buf)                 # OK — an independent copy is stored; buf is yours
```

This is the whole design in miniature. **The common case — the function borrows your place — is free.** The consequential case — the function takes ownership, and afterward your `buf` is gone — is *marked*, right there at the call site, with one word. You never pay ceremony to say "just look at it" or "just change it." You pay exactly one word, exactly once, to say "here, keep it" — at the one moment that decision actually matters and a future reader deserves to see it.

Contrast the two languages that bracket us:

- **Rust** makes *every* by-value pass a move, so `store(buf)` silently consumes `buf` and you learn about it only when you try to use `buf` again and the compiler stops you. The transfer is real but invisible at the call site.
- **C++** makes you write `std::move(buf)` — but forgetting it doesn't error, it silently makes a *copy*, and now you have a performance bug you can't see.

With threads the needle: the transfer is **visible** (you wrote `move`) and forgetting it is **loud** (a compile error, never a silent copy). The call site never lies to you about what happens to your value.

## How the compiler knows

Here's the part that feels like magic and is actually just good engineering: *you never tell the compiler which mode to use.* It figures it out.

Every function gets an **effect summary** — a compact, inferred record of what it does to each parameter:

- **read** — it looks at the value
- **write** — it mutates the value in place
- **consume** — it takes ownership and uses the value up internally
- **escape** — it stores or returns the value beyond the call
- **escape-view** — it returns a *reference* into the value

The compiler derives this by reading the function's body, the same way it derives types. A parameter that's only read or written is **share-place** — borrow the caller's place, no ceremony. A parameter that's consumed or escapes needs **ownership** — and *that's* the case where you write `move` or `copy`. Returning a view into a parameter is handled by lifetime tracking that the compiler infers for you — no `<'a>` annotations, ever.

And because a function's effect on a parameter can flow through the functions *it* calls, the compiler solves the whole thing as a fixpoint over your program's call graph — exactly the way a modern compiler already does escape analysis to decide stack-vs-heap. We just point that same machinery at a more useful question: *does this call need to take ownership, or can it borrow your place?*

The borrow checker then does what borrow checkers do — but on a model shaped for humans. If you hold a reference into `buf` and then call a function that writes to `buf`, that's a conflict, and it's caught statically. Multiple readers: fine. A writer with a live reader: rejected. You get Rust-comparable aliasing safety, and you wrote none of the annotations that usually buy it.

## Why no one else does this

Share-place isn't a wild new invention. It's a *synthesis* — and the interesting thing is that each piece is already proven in a production compiler, just never assembled this way:

- **Zig** already passes value parameters by pointer-to-the-caller's-data when it's safe to, "whichever way will be faster" — but only because Zig parameters are immutable, so you can never observe the aliasing. With takes that same ABI trick and makes the mutation *observable and intentional*, which is the whole point.
- **Go's** escape analysis is exactly the inference we need: a call-graph fixpoint that computes, per parameter, whether a value escapes — and encodes it into the function's interface. We ask it a slightly different question and use the answer to pick the calling mode.
- **Rust** already infers, for closures, whether each captured variable is borrowed, mutably borrowed, or moved — by reading how the body uses it. With generalizes that inference from closures to *every* parameter.
- **Vale** contributes the ownership model itself: single ownership with consuming destructors, memory-safe without a tracing GC.

Zig's ABI, Go's analysis, Rust's inference, Vale's ownership — four ideas that each ship in a real compiler today, unified behind a single question asked at every call. No one language had put them together, because no one language had decided that the *default* should be "borrow the caller's place, mutably, safely, and say nothing." With decided exactly that, because it's the thing that removes the most suffering.

## Why you're going to love it

Because the code you write stops being about the compiler and goes back to being about the problem.

You write `bump(counter)` and it bumps your counter. You write `normalize(vec)` and it normalizes your vector. You pass things to functions and they do things to those things, and it reads like the pseudocode you'd write on a whiteboard — and it compiles to native code with no GC, and it's memory-safe, and you never wrote `&mut`, never threaded a lifetime, never cloned defensively "just to make the borrow checker happy."

And on the rare day you *do* hand something off for keeps, you write one honest word — `move` — and every future reader of that line knows, at a glance, that ownership changed hands right there.

That's the deal With is offering: **native control, Rust-level safety, C-level reach — with the suffering automated away.** Share-place is where that promise gets cashed at the most basic operation in all of programming: calling a function and handing it a value.

You've been paying a tax on that operation your whole career. With just stopped charging it.

---

*Historical closing claim (superseded): this post originally called
free-parameter SHARE-PLACE canonical. That claim is false under current §3.8.
The receiver modes it discussed survive independently under D12/D21.*
