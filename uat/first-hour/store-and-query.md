# Store rows and query them back

**The task, as a user brings it.** "Keep a small table of notes in a database file: add a note from the command line, list them all, and search them by a word."

**The library they reach for.** sqlite3 (`with get c.sqlite3`).

**Done when** `add`, `list` and `find <word>` work against a file that survives between runs, a search with no match prints nothing and exits 0, and a note containing a quote character is stored and found unchanged.
