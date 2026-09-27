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
init` writes `uat/hello.uat` and `uat/README.md`.
