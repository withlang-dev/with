//! expect-stdout: ok

// D51 §41 / §16.1, §16.2b.8: a foreign string is a `CStr` view, and With
// text is made from it explicitly — `to_str()` validates (a `&str` over the
// same bytes), `to_str_lossy()` repairs, `to_owned()` copies. `strerror`
// and `getenv` are items of the toolchain libc facade (stage 7), so their
// results are `Option[CStr]` borrowed from their domains; `CStr.from_ptr`
// is the `unsafe` spelling for a pointer C handed back with no facade.
use c_import("char *getenv(const char *name);\nchar *strerror(int code);\n")

fn main:
    let message = strerror(2).unwrap().to_owned()
    assert(message.len() > 0 and not message.contains("\0"))
    let text = strerror(2).unwrap()
    assert(text.to_str().unwrap() == message)
    assert(text.to_str_lossy() == message)

    let view = unsafe { CStr.from_ptr(c"with".ptr) }
    assert(view.len() == 4 and view.to_owned() == "with")
    assert(unsafe { CStr.from_ptr(c"".ptr) }.to_owned() == "")

    // to_str validates and never repairs; to_str_lossy repairs, explicitly.
    assert(c"héllo".to_str().unwrap() == "héllo")
    let bad = unsafe { CStr.from_ptr(c"a\xffb".ptr) }
    assert(bad.to_str().is_err())
    assert(bad.to_str_lossy().len() == 5)

    // Null is information: a nullable return is an Option before it is a view.
    let missing = getenv("WITH_NO_SUCH_VARIABLE_").map(p => p.to_owned())
    assert(missing == None)
    print("ok")
