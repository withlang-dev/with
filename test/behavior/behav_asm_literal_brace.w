//! expect-stdout: ok

// §16.13 literal braces: {{ and }} render single braces; no placeholder lookup.

fn main:
    unsafe:
        asm volatile("nop // {{esc}}")
    print("ok")
