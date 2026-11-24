# Serve MCP over standard input and output

**The task, as a user brings it.** "Write a small MCP server: it reads JSON-RPC requests line by line from standard input, answers `initialize`, lists one tool, and runs that tool (echo its argument back) when called."

**The library they reach for.** `std.json` and the standard input and output of `std.io`.

**Done when** a scripted session of `initialize`, `tools/list` and `tools/call` gets three well-formed responses, a malformed line gets a JSON-RPC error and the server keeps running, and end of input ends the server with status 0.
