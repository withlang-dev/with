//! expect-stdout: header pair: true true
//! expect-stdout: write pair: true true
//! expect-stdout: ok
//! skip-on: windows issue #800: action/capability/net/process/fs OS-surface fails on native Windows

// #3113 (§16.2b.9): each callback case of a variadic contract is its own
// pair with its own `U`. Only the first-listed case was callable: a setter
// of any later callback case failed "cannot infer generic method type
// parameter 'U'".
use c_import("curl/curl.h", link: "curl")

c facade curl_two_pairs:
    resource Easy wraps *mut CURL
        from curl_easy_init
        drop curl_easy_cleanup
        abandon curl_easy_reset
    fn curl_easy_init
        rename new
    fn curl_easy_reset
        rename reset
        lend
        callbacks none
    fn curl_easy_setopt
        callback_thread registering
        rename setopt
        callbacks none
        ok CURLE_OK
        variadic param 2 selected by param option:
            case CURLOPT_WRITEFUNCTION: callback param 2 as curl_write_callback userdata param CURLOPT_WRITEDATA retains by param 0
            case CURLOPT_HEADERFUNCTION: callback param 2 as curl_write_callback userdata param CURLOPT_HEADERDATA retains by param 0

fn on_chunk(ptr: *mut c_char, size: u64, nmemb: u64, sink: &fn(i32) -> Unit) -> u64:
    sink((size * nmemb) as i32)
    size * nmemb

fn configure() -> bool:
    var head: i32 = 0
    var body: i32 = 0
    let head_sink = n => head = head + n
    let body_sink = n => body = body + n
    let made = Easy.new()
    if made.is_none(): return false
    var easy = made.unwrap()
    let h1 = easy.setopt(CURLOPT_HEADERFUNCTION, on_chunk)
    let h2 = easy.setopt(CURLOPT_HEADERDATA, head_sink)
    print(f"header pair: {h1 == CURLE_OK} {h2 == CURLE_OK}")
    let w1 = easy.setopt(CURLOPT_WRITEFUNCTION, on_chunk)
    let w2 = easy.setopt(CURLOPT_WRITEDATA, body_sink)
    print(f"write pair: {w1 == CURLE_OK} {w2 == CURLE_OK}")
    h1 == CURLE_OK and h2 == CURLE_OK and w1 == CURLE_OK and w2 == CURLE_OK

fn main:
    if curl_global_init(CURL_GLOBAL_DEFAULT) != CURLE_OK:
        print("libcurl global init failed")
        return 1
    if configure(): print("ok")
    curl_global_cleanup()
