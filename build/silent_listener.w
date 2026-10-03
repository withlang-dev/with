use std.fs
use std.net
use std.process
use std.time

// `with build :source-fetch-tests`: a server that accepts a connection and
// never answers (build/source_fetch.w's stalled-source case).
//
//   silent_listener <port-file>   listen on a free port, write it to the
//                                 file, and hold the socket for 12 seconds
//                                 without accepting: the kernel completes
//                                 each connection, nothing is ever sent
//   silent_listener nap           sleep a second (the action has no clock)

fn main -> i32:
    let argv = args()
    if argv.len() < 2:
        print("usage: silent_listener <port-file> | silent_listener nap")
        return 2
    if argv[1] == "nap":
        sleep_secs(1)
        return 0
    let fd = tcp_listen(0)
    if fd < 0:
        print("could not listen")
        return 1
    let port = sock_port(fd)
    if port <= 0 or write_file(argv[1], f"{port}\n") != 0:
        print("could not write the port")
        return 1
    sleep_secs(12)
    let _ = socket_close(fd)
    0
