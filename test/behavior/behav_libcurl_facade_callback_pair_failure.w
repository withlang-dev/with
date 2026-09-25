//! expect-stdout: first: true
//! expect-stdout: second: false
//! expect-stdout: configured: false
//! expect-stdout: ok
//! skip-on: windows issue #800: action/capability/net/process/fs OS-surface fails on native Windows

// D66's required acceptance case (#1652, spec §16.2b.9): the first setter
// succeeds, the second fails, the function returns an error, and cleanup
// stays safe and releases the retained state exactly once. This facade
// pairs the write callback with a deliberately invalid userdata selector
// (CURLOPT_LASTENTRY, "the last unused"; libcurl answers
// CURLE_UNKNOWN_OPTION) so the second setter fails for real with the real
// variadic ABI. The failure leaves the pair incompatible; the handle's Drop
// on the error return runs curl_easy_reset — the abandonment path — before
// curl_easy_cleanup, so cleanup cannot invoke the half-configured pair.
// This is a test facade: the invalid selector never enters lib/facades.
use c_import("curl/curl.h", link: "curl")

c facade curl_pair_failure:
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
        rename setopt
        callbacks none
        ok CURLE_OK
        variadic param 2 selected by param option:
            case CURLOPT_WRITEFUNCTION: callback param 2 as curl_write_callback userdata param CURLOPT_LASTENTRY retains by param 0
    fn curl_easy_perform
        rename perform
        lend

fn on_data(ptr: *mut c_char, size: u64, nmemb: u64, sink: &fn(i32) -> Unit) -> u64:
    sink((size * nmemb) as i32)
    size * nmemb

fn configure() -> bool:
    var total = 0
    let sink = n => total = total + n
    let made = Easy.new()
    if made.is_none(): return false
    var easy = made.unwrap()
    let first = easy.setopt(CURLOPT_WRITEFUNCTION, on_data)
    print(f"first: {first == CURLE_OK}")
    if first != CURLE_OK: return false
    let second = easy.setopt(CURLOPT_LASTENTRY, sink)
    print(f"second: {second == CURLE_OK}")
    if second != CURLE_OK: return false
    easy.perform() == CURLE_OK

fn main:
    if curl_global_init(CURL_GLOBAL_DEFAULT) != CURLE_OK:
        print("libcurl global init failed")
        return 1
    print(f"configured: {configure()}")
    curl_global_cleanup()
    print("ok")
