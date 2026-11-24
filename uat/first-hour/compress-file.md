# Compress a file and read it back

**The task, as a user brings it.** "Compress a file to `name.zst` and decompress it again; the round trip must give the same bytes."

**The library they reach for.** zstd (`with get c.zstd`).

**Done when** `pack <file>` and `unpack <file.zst>` work on a file of a few megabytes, larger than any buffer the program sized up front, the round trip is byte-identical, and a truncated `.zst` is reported as an error.
