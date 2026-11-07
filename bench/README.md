# Benchmark

Run `make bench GOOSE=/absolute/path/to/matching/goose`. The default output is
`.build/benchmark.json`. The runner builds an optimized standalone Goose consumer,
warms both modes, alternates mode order, and retains seven raw process samples.
Workloads cover a short diagnostic (10,000 searches), 256 KiB matched input
(128), 256 KiB no-match input (128), 32 captures (10,000), and a nested repetition
that must stop at work limit 1,000 (1,000). `reuse` compiles
once; `compile` additionally compiles/closes each iteration. Both validate a
checksum. Source hashes, executable hashes, compiler pin, backend version,
platform, CPU affinity and compiler identification accompany samples.

Process startup, wrapper checks, registry locks and output copying are included.
These are fixed reuse experiments, not a comparison against another regex engine,
a proof of allocation-free searches, or a general performance claim. Shared host
load affects results. Preserve raw samples and slower results. Build/setup time
is excluded. Run broader workloads and profile before changing hot paths.
