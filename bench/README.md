# Benchmark

Run `make bench GOOSE=/absolute/path/to/matching/goose`. The default output is
`.build/benchmark.json`. The runner builds an optimized standalone Goose consumer,
warms both modes, alternates mode order, and retains seven raw process samples.
Each process executes 10,000 searches on one compiler diagnostic. `reuse` compiles
once; `compile` additionally compiles/closes each iteration. Both validate a
checksum. Source hashes, executable hashes, compiler pin, backend version,
platform, CPU affinity and compiler identification accompany samples.

Process startup, wrapper checks, registry locks and output copying are included.
This is a narrow reuse experiment, not a comparison against another regex engine,
a proof of allocation-free searches, or a general performance claim. Shared host
load affects results. Preserve raw samples and slower results. Build/setup time
is excluded. Run broader workloads and profile before changing hot paths.
