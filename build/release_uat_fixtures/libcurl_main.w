use c_import("curl/curl.h")

fn main:
    let init_rc = curl_global_init(CURL_GLOBAL_DEFAULT)
    if init_rc != CURLE_OK:
        print("libcurl global init failed")
        return 1

    let easy = unsafe { curl_easy_init() }
    if easy == null:
        print("libcurl easy init failed")
        curl_global_cleanup()
        return 1

    let opt_rc = unsafe { curl_easy_setopt(easy, CURLOPT_NOSIGNAL, 1 as c_long) }
    if opt_rc != CURLE_OK:
        print("libcurl setopt failed")
        unsafe { curl_easy_cleanup(easy) }
        curl_global_cleanup()
        return 1

    let info = unsafe { curl_version_info(CURLVERSION_NOW) }
    if info == null:
        print("libcurl version info failed")
        unsafe { curl_easy_cleanup(easy) }
        curl_global_cleanup()
        return 1
    if unsafe { info.version } == null:
        print("libcurl version missing")
        unsafe { curl_easy_cleanup(easy) }
        curl_global_cleanup()
        return 1

    unsafe { curl_easy_cleanup(easy) }
    curl_global_cleanup()
    write("libcurl UAT passed\n")
