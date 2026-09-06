use std.string

fn main:
    print(f"i123={string_to_int("123")} ineg={string_to_int("-42")} iplus={string_to_int("+7")}")
    print(f"iinv={string_to_int("abc")} iempty={string_to_int("")} ipart={string_to_int("12x34")} itrail={string_to_int("  12")}")
    print(f"parse={parse("99")} parseinv={parse("zz")}")
