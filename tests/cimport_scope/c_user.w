// c_user.w — A module that uses c_import internally.
// Its c_import symbols (printf, etc.) should NOT leak to importers.

use c_import("<stdio.h>")

fn c_user_greeting() -> str:
    "hello from c_user"
