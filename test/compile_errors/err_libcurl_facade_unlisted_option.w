//! expect-check-fail: add 'case CURLOPT_WRITEDATA: <type>' under 'variadic param 2 selected by param option:' in facade curl, or call the raw curl_easy_setopt under unsafe

// D66 (spec §16.2b.5): an option the facade lists no case for is refused
// on the safe surface, naming the case to add; CURLOPT_WRITEDATA is the
// userdata half of a callback pairing (#1652), and its raw call stays
// available under unsafe.
use facades.libcurl
use c_import("curl/curl.h", link: "curl")

fn main:
    let easy = Easy.new().unwrap()
    var n: i32 = 0
    let rc = easy.setopt(CURLOPT_WRITEDATA, &raw mut n)
    print(f"{rc}")
