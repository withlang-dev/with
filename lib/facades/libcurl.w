// The libcurl facade — D66 (spec §16.2b.5 "Discriminated variadic
// contracts", §16.2b.6 "Borrowed record views"): the first facade written
// against the variadic ruling, over the real `curl/curl.h` (the one
// `c_import` resolves on the host), and the surface the release UAT program
// and a plain transfer need. Every sentence a clause relies on is quoted
// beside it, from the libcurl manual (https://curl.se/libcurl/c/<fn>.html).
//
// Where it lives: as `lib/facades/sqlite3.w` — the project's own facade
// under the repository's `lib/` (§16.2b.1; `c.libcurl` ships none yet), and
// the release UAT copies it into the fresh project as src/facades/libcurl.w.
//
// What the ruling asks for and where it is met (D66):
//   CURL as an owned pointer resource ............... resource Easy
//   NULL-signalled production ....................... from curl_easy_init (Option[Easy])
//   curl_easy_cleanup ............................... drop
//   the variadic setopt, case by case ............... variadic param 2 selected by param option
//   a long, a copied string, a curl_off_t ........... case CURLOPT_NOSIGNAL / CURLOPT_URL / …
//   the callback and retained-pointer cases ......... left out (#1652); raw under unsafe
//   the version record as a borrowed record view .... returns borrow curl_version_info_data from domain version_info
//   its mutator ..................................... curl_global_init (nothing states `preserves` on it)
//   static text ..................................... curl_version, curl_easy_strerror: returns static CStr
//   the transfer .................................... curl_easy_perform: lend, presenting the CURLcode
//
//     let easy = Easy.new()?                          // None: "something went wrong"
//     easy.setopt(CURLOPT_URL, "https://example.com") // a copied string
//     easy.setopt(CURLOPT_NOSIGNAL, 1)                // a long
//     let code = easy.perform()
//     if code != CURLE_OK: print(curl_easy_strerror(code).unwrap())
use c_import("curl/curl.h", link: "curl")

c facade curl:
    // curl_version_info(3): "Returns a pointer to a filled in static struct
    // with information about various features in the running version of
    // libcurl." A pointer into libcurl's process-wide state: its origin is
    // a foreign-state domain, never `static` — the record may change until
    // curl_global_init has run (D66: "libcurl may alter it until
    // curl_global_init"), and nothing here states `preserves` on
    // curl_global_init or curl_global_cleanup, so a view taken before
    // either dies at it (§16.2b.7: unknown effect means invalidate).
    domain version_info process
    // curl_easy_init(3): "This function returns a CURL easy handle that you
    // must use as input to other functions in the easy interface. This call
    // must have a corresponding call to curl_easy_cleanup when the
    // operation is complete." — an owned pointer resource, produced by
    // direct return, `None` when "this function returns NULL, something
    // went wrong and you cannot use the other curl functions" (§16.2b.4:
    // trusted evidence that NULL signals failure; no `ok` is needed).
    // curl_easy_cleanup(3): "This function is the opposite of
    // curl_easy_init. It closes down and cleans up the resources associated
    // with a CURL easy handle." — the automatic Drop.
    //
    // Threads: libcurl-thread(3) says "You must never share the same handle
    // in multiple threads. You can pass the handles around among threads,
    // but you must never use a single handle from more than one thread at
    // any given time." The passing is `send`, which needs a stated
    // `drop_any_thread` the manual does not spell, so nothing is granted
    // here (§16.2b.10: never inferred); a facade that adopts the sentence
    // as trusted evidence may state `thread send drop_any_thread`.
    resource Easy wraps *mut CURL
        from curl_easy_init
        drop curl_easy_cleanup
    // The presentation override (§16.2b.11): the convention would present
    // curl_easy_init as `Easy.easy_init`; a handle is made with `Easy.new`.
    fn curl_easy_init
        rename new
    // curl_easy_setopt(3): "curl_easy_setopt is used to tell libcurl how to
    // behave. … All options are set with an option followed by a parameter.
    // That parameter can be a long, a function pointer, an object pointer
    // or a curl_off_t, depending on what the specific option expects." The
    // declaration is variadic and stays so (§16.2b.5); each case states
    // what the option expects, from that option's page. "Strings passed to
    // libcurl as 'char *' arguments, are copied by the library; the string
    // storage associated to the pointer argument may be discarded or
    // reused after curl_easy_setopt returns. The only exception to this
    // rule is really CURLOPT_POSTFIELDS" — so a `char *` option is a
    // copied `str`, and CURLOPT_POSTFIELDS, whose data "is NOT copied",
    // is not listed (a retained case, #1652), nor are the callback options
    // (CURLOPT_WRITEFUNCTION with CURLOPT_WRITEDATA, #1652): they are the
    // raw curl_easy_setopt under unsafe until the pairing is modeled.
    //   CURLOPT_NOSIGNAL(3):        "Pass a long. If it is 1, libcurl uses
    //                                no functions that install signal handlers"
    //   CURLOPT_URL(3):             "Pass in a pointer to the URL to work
    //                                with. The parameter should be a char *
    //                                to a null-terminated string" … "The
    //                                application does not have to keep the
    //                                string around after setting this option."
    //   CURLOPT_VERBOSE(3):         "Set the onoff parameter to 1 to make the
    //                                library display a lot of verbose
    //                                information"
    //   CURLOPT_TIMEOUT(3):         "Pass a long as parameter containing
    //                                timeout - the maximum time in seconds
    //                                that you allow the transfer operation
    //                                to take."
    //   CURLOPT_CONNECTTIMEOUT(3):  "Pass a long. It sets the maximum time in
    //                                seconds that you allow the connection
    //                                phase to take."
    //   CURLOPT_FOLLOWLOCATION(3):  "A long parameter set to 1 tells the
    //                                library to follow any Location: header"
    //   CURLOPT_MAXREDIRS(3):       "Pass a long. The set number is the
    //                                redirection limit amount."
    //   CURLOPT_USERAGENT(3):       "Pass a pointer to a null-terminated
    //                                string as parameter. It is used to set
    //                                the User-Agent: header"
    //   CURLOPT_MAXFILESIZE_LARGE(3): "Pass a curl_off_t as parameter. This
    //                                specifies the maximum accepted size (in
    //                                bytes) of a file to download."
    fn curl_easy_setopt
        rename setopt
        preserves domain version_info
        variadic param 2 selected by param option:
            case CURLOPT_NOSIGNAL: c_long
            case CURLOPT_URL: str
            case CURLOPT_VERBOSE: c_long
            case CURLOPT_TIMEOUT: c_long
            case CURLOPT_CONNECTTIMEOUT: c_long
            case CURLOPT_FOLLOWLOCATION: c_long
            case CURLOPT_MAXREDIRS: c_long
            case CURLOPT_USERAGENT: str
            case CURLOPT_MAXFILESIZE_LARGE: curl_off_t
    // curl_easy_perform(3): "Perform the transfer as described in the
    // options." "Returns CURLE_OK (0) on success and a non-zero value on
    // error." A status with nothing produced: `ok CURLE_OK` projects a
    // producer or a copied-back length (§16.2b.4, §16.2b.8), not a plain
    // operation, so the code is presented as the manual states it and
    // curl_easy_strerror names it.
    fn curl_easy_perform
        rename perform
        lend
        preserves domain version_info
    // curl_easy_reset(3): "Re-initializes all options previously set on a
    // specified CURL handle to the default values."
    fn curl_easy_reset
        rename reset
        lend
        preserves domain version_info
    // curl_version(3): "Returns a human readable string with the version
    // number of libcurl and some of its important components (like OpenSSL
    // version)." "We recommend using curl_version_info instead" — this is
    // the printable text; the pointer "must not be freed", and the string
    // is static for the whole program (§16.2b.7: stated, never inferred).
    fn curl_version
        returns static CStr
        preserves domain version_info
    // curl_easy_strerror(3): "The curl_easy_strerror function returns a
    // string describing the CURLcode error code passed in the argument
    // errornum." "The string is static and must not be freed" — static text
    // (§16.2b.7).
    fn curl_easy_strerror
        returns static CStr
        preserves domain version_info
    // The version record, as a borrowed record view (D66, §16.2b.6): a
    // pointer into a static struct of the domain declared above. Its scalar
    // fields (`version_num`, `age`, `features`) are readable through the
    // view; its pointer fields (`version`, `host`, `ssl_version`, …) stay
    // raw pointers until a field-level ruling states their contract — the
    // printable version text is curl_version() above.
    fn curl_version_info
        returns borrow curl_version_info_data from domain version_info
        preserves domain version_info
    // curl_global_init(3): "This function sets up the program environment
    // that libcurl needs. Think of it as an extension of the library
    // loader." It takes a `long` and returns a `CURLcode`; nothing about it
    // is raw, and it is the operation the version record may change at, so
    // it states no preservation. curl_global_cleanup(3): "This function
    // releases resources acquired by curl_global_init." Both are described
    // so their calls are the facade's, and the domain's library, on record.
    fn curl_global_init
        lend
    fn curl_global_cleanup
        lend
