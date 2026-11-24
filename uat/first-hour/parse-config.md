# Parse a JSON configuration file

**The task, as a user brings it.** "Read `config.json`: a server name, a port, a list of allowed hosts and an optional timeout. Tell me clearly what is wrong when the file is malformed or a field has the wrong type."

**The library they reach for.** `std.json` first; yyjson (`with get c.yyjson`) if the standard module does not cover it.

**Done when** a good file prints its four values, a missing optional field takes a default, and a malformed file, a missing required field and a wrong type each give an error that names the field or the position.
