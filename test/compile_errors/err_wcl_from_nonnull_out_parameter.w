//! expect-check-fail: 'from box_open, nonnull': box_open produces through an out parameter

// §31.8.2: an out-parameter producer's status says whether anything was
// produced; `nonnull` is about a returned pointer.
use c_import("#define BOX_OK 0
typedef struct box box;
int box_open(int n, box **out);
void box_free(box *b);
")

c contract boxes:
    resource Crate wraps *mut box
        from box_open(out param 1), nonnull
        drop box_free
        ok BOX_OK

fn main:
    print("x")
