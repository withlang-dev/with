//! expect-check-fail: a fixed argument on 'note_free_with' is not modeled
//! expect-check-fail: = help: delete 'param N fixed …' under 'fn note_free_with'

// #3129 (§16.2b.11): a destroyer takes only what the resource passes it.
use c_import("typedef struct note note;\nenum st { ST_OK = 0 };\nnote *note_new(void);\nint note_open(note **out);\nvoid note_free(note *n);\nvoid note_free_with(note *n, int flag);\nvoid note_write(note *n, const char *src, unsigned long len);\nvoid note_reset(note *n);\nvoid note_reset_to(note *n, int v);\nconst char *last_msg(int code);\nvoid other_reset(int v);\n")

c contract notes:
    resource Note wraps *mut note
        from note_new
        drop note_free
        destroys note_free_with
    fn note_free_with
        param flag fixed 0

fn main:
    print("unreachable")
