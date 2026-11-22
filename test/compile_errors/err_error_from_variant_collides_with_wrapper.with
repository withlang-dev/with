//! expect-error: variant 'Db' of error 'E' has the name of the wrapper variant generated for 'DbError'

// §10.9 / D57: a written variant whose name equals a generated wrapper's
// name is a compile-time error; the compiler never picks between them.

error DbError =
    | Timeout

error E from DbError =
    | Db(str)

fn main:
    print("unreachable")
