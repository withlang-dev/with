# 18.5d Acceptance scenarios

A project's `uat/` directory holds acceptance scenarios: plain-text files,
one per scenario, each a header (`scenario:`, optional `requires:` and
`platforms:`) followed by steps a person would perform at a terminal — `new
directory`, `run:`, `write … from …`, `stdin:`, `env`, and `expect …` lines
for the exit status, output, files and images. `with uat` runs every
scenario that applies on the host, skips with a reason the ones whose
`requires:` are unmet, and reports one verdict per scenario and one line
per failed step. `expect (human):` records a check a person performs; the
runner prints it and never fails it. Programs a scenario writes into the
project come from `uat/fixtures/` and are ordinary source files. `with
init` writes `uat/hello.uat` and `uat/README.md`. In a checkout that holds
the package registry (`registry/README.md`, §16.2b.15), a scenario's `with
get` reads that checkout's facts (`WITH_REGISTRY=file://<root>`, set by
the runner unless the caller set it): the battery proves the tree, its
facts included, before they reach the repository's `main`. A
`platforms:` entry is an OS (`darwin`, `linux`, `windows`), an
architecture (`aarch64`, `x86_64`), or an os-arch pair
(`linux-x86_64`) — the test gates' forms; an unknown value skips the
scenario with that reason rather than running it everywhere.
