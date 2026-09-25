//! expect-check-fail: add 'case CURLOPT_READDATA: <type>' under 'variadic param 2 selected by param option:' in facade curl, or call the raw curl_easy_setopt under unsafe

// D66 (spec §16.2b.5): an option the facade lists no case for is refused
// on the safe surface, naming the case to add. CURLOPT_READDATA is the
// userdata half of the read callback, which this facade does not pair
// (the write pair is, §16.2b.9); its raw call stays
// available under unsafe.
use facades.libcurl
use c_import("curl/curl.h", link: "curl")

fn main:
    let easy = Easy.new().unwrap()
    var n: i32 = 0
    let rc = easy.setopt(CURLOPT_READDATA, &raw mut n)
    print(f"{rc}")
