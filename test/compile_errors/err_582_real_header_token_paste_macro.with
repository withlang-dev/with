//! expect-error: c_import symbol 'PASTE' was omitted
//! expect-error: token pasting
// #582: a token-paste macro from a real header file is omitted with the
// §16.2 diagnostic naming it and why, as from an inline header spec; it was
// a bare "undefined variable". Only an inline spec recorded function-like
// macro omissions.
use c_import("err_582_real_header_token_paste_macro.h")

fn main:
    print(ANSWER)
    print(PASTE(1, 2))
