# Verify a signature over a message

**The task, as a user brings it.** "I have a public key, a message file and a detached Ed25519 signature. Tell me whether the signature is good."

**The library they reach for.** libsodium (`with get c.libsodium`).

**Done when** a good signature prints `ok` and exits 0, a changed message or signature prints `bad signature` and exits 1, and a key or signature of the wrong length is an error that says so.
