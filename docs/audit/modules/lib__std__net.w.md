# Primary verification — `lib/std/net.w` + `lib/std/http.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: net `dc60f7e5526662e6a26c687166cac82c3c13f7c74a3da0fa513f518a49c80b0e`;
http `71c84d23d2d1c8c3eabe9f3cff757fe22b528b6357a10f64f3013dc070a3c71e`
Source examined: child both complete + rt/linux_x86_64.w:713-846; primary:
net.w 1-52 FULL READ, rt send/recv :810-843 (full read), full probe re-runs below

## Scope examined

Socket API honesty, error propagation, protocol scope.

Applicable overview targets examined: T10 (honesty), T15 (correctness), T23 (errors).

## Behavioral matrix

`p1_bind.w` + `p2_errors.w` re-run by primary, all pass: ephemeral bind +
sock_port, rebind -98, bad-port -22, bad-fd -9s, refused -1, dnsfail -1,
udp connect-to-unbound ok (correct UDP semantics), closes 0.

## NET-001 — doc-code contradictions (filed #1011, LOW)

Classification: **Confirmed doc falsehoods with caller-visible consequences; #1011**
Severity: **Low** — one-line doc fixes, but the -1 fiction breaks error checks
Confidence: **Very high** (full file read + rt read + probes)

1. `send` doc "-1 on error" vs implementation -errno (observed -9):
   `== -1` checks miss real errors. Implementation itself is GOOD (EINTR
   retry, partials) — only the doc lies.
2. `socket_close` "0 on success" silent on failure values; IPv4-only nowhere
   documented.
3. Explicitly NOT defects (bounded in the issue): connect -1 coarseness
   (documented), recv-"" conflation (documented), udp-connect success
   (correct semantics).

## Notes

- Episode: shell backticks in the original `gh issue create --body` were
  executed by sh, mangling two lines; repaired via --body-file and verified.
  Process rule: issue bodies go through files, never shell-quoted.
