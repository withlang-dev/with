# POST JSON with headers and read the status

**The task, as a user brings it.** "I have an HTTP API that takes JSON. Send it a POST with a JSON body, an `Authorization` header and a `Content-Type` header, and tell me the status code and the response body."

**The library they reach for.** libcurl (`with get c.libcurl`).

**Done when** the program prints the status code and the body for a URL given on the command line, and exits non-zero with a message when the request fails.

**Platforms.** darwin and linux (`linux-aarch64` builds libcurl against mbedtls 3.6 from source, #2757).
