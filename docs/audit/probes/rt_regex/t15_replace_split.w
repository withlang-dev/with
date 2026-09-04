use std.io
use std.regex.Regex

fn check(name: str, cond: bool):
    if cond:
        print_str("PASS ")
    else:
        print_str("FAIL ")
    print_str(name)
    print_str("\n")

fn main:
    // substitute path (with_regex_substitute): global replace_all
    match Regex.compile("\\d+"):
        Ok(re) => {
            let all = re.replace_all("a1b22", "#")
            check("replace-all", all == "a#b#")
            let one = re.replace("a1b22", "#")
            check("replace-one", one == "a#b22")
        }
        Err(e) => {
            print_str("COMPILE-FAIL subst ")
            print_str(e.message.clone())
            print_str("\n")
        }
    // split path
    match Regex.compile(","):
        Ok(re) => {
            let parts = re.split("a,b,c")
            check("split-n", parts.len() as i32 == 3)
            check("split-0", parts.get(0) == "a")
            check("split-2", parts.get(2) == "c")
        }
        Err(e) => {
            print_str("COMPILE-FAIL split ")
            print_str(e.message.clone())
            print_str("\n")
        }
    // find_all over repeated matches
    match Regex.compile("[a-z]+"):
        Ok(re) => {
            let all = re.find_all("ab 12 cd")
            check("find-all-n", all.len() as i32 == 2)
        }
        Err(e) => {
            print_str("COMPILE-FAIL findall ")
            print_str(e.message.clone())
            print_str("\n")
        }
