//! expect-check-fail: resource 'Handle': producer 'handle_dup' receives param 0: *const handle h, another 'Handle'; a resource that depends on one of its own type is not modeled
//! expect-check-fail: = help: state 'independent' when what 'handle_dup' returns shares nothing with the one it is given; otherwise leave 'handle_dup' raw

// A producer handed one of its own resource (a copy) would make the resource
// depend on its own type. The checker reported that as a compiler defect
// ("the renderer and the dependency facts classified its producers
// differently"); it is a contract error that names the clause to state.
use c_import("typedef struct handle handle;\nhandle* handle_new(void);\nhandle* handle_dup(const handle* h);\nvoid handle_free(handle* h);\n")

c contract traced:
    resource Handle wraps *mut handle
        from handle_new
        from handle_dup
        drop handle_free

fn main: print(1)
