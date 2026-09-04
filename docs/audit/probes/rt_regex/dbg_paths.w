use std.io
use std.regex.Regex

fn main:
    match Regex.compile("(a)(b)"):
        Ok(re) => {
            print_str("compiled caps=")
            print_int(re.num_captures())
            print_str("\n")
            print_str("is_match_ab=")
            if re.is_match("ab"):
                print_str("true\n")
            else:
                print_str("false\n")
            print_str("is_match_xx=")
            if re.is_match("xx"):
                print_str("true\n")
            else:
                print_str("false\n")
            match re.find("xxab"):
                Some(m) => {
                    print_str("find start=")
                    print_int(m.start)
                    print_str(" end=")
                    print_int(m.end)
                    print_str("\n")
                }
                None => {
                    print_str("find NONE\n")
                }
        }
        Err(e) => {
            print_str("ERR ")
            print_str(e.message.clone())
            print_str("\n")
        }
    match Regex.compile("("):
        Ok(re) => {
            print_str("invalid compiled?!\n")
        }
        Err(e) => {
            print_str("invalid-err code=")
            print_int(e.code)
            print_str(" msg=")
            print_str(e.message.clone())
            print_str("\n")
        }
