//! expect-check-fail: 'cwd' is process-global state: an effect the runtime audit records, not a domain, until a facade presents a safe view whose validity it decides

// Spec §16.2b.14 (D76, ruling Amendment 2, #1608): process-global C state
// over which no safe view is presented is an effect the runtime audit
// records, not a domain. "It becomes a domain the first time a facade
// presents a safe view whose validity it decides" — text borrowed from the
// working directory is such a view, so the facade presenting it declares
// `domain cwd`, or the view has no origin a `chdir` could be seen to
// invalidate.
use c_import("const char *cwd_text(void);\n")

c facade posixish:
    fn cwd_text
        returns borrow CStr from domain cwd

fn main:
    print(f"{cwd_text().is_some()}")
