# Contributing

Use focused feat/..., fix/... and docs/... branches and Conventional Commits,
for example `fix: reject stale pattern tokens`. Each commit should represent
one coherent change. Never commit credentials, binaries, caches or private
workspace notes. Do not move published tags; use semantic versions.

Use the full upstream compiler commit in GOOSE_REVISION. Run:

```sh
make format check test test-debug
make sanitize CC=clang
make sanitize CC=gcc
make fuzz FUZZ_RUNS=10000
```

Native changes require independent review and regression cases for every
observable fix. Test malformed input, bounds, allocation failure, stale aliases,
empty outputs, ownership and concurrency. Keep file/process I/O in consumers.
Preserve the small interface and explicit error rules; discuss additions before
implementation. Keep native code private and bounded. There is no portable
fallback in this PCRE2 adapter; do not claim goose-json's portable-codec coverage.

Profile before optimizing. Keep fixtures, raw samples, slower results, exact
source/dependency/toolchain identities and workload limitations. CI checks
execution, never timing thresholds. Read SECURITY.md for private reporting.
