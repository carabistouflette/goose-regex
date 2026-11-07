# Bounded byte regular expressions

The first consumer is examples/diagnostics.goose: extract compiler-style
file:line:column records without allocating capture strings. Honk integration
is a separate decision.

The interface is compile, find, close. A Pattern contains a checked native token,
not a pointer. Copies alias one reusable compiled pattern and match workspace.
Close invalidates all aliases. Native registry locking covers only slot leases;
concurrent operations on the same handle return Busy. Unrelated handles run in
parallel. Slots are never reused with the same token.

PCRE2 8-bit interpreter, no JIT. UTF/UCP activation is prohibited. Patterns and
subjects accept embedded NUL. Captures are half-open byte offsets; unmatched
captures are (-1,-1). Capture zero is the whole match. Structurally valid outputs
reset before handle/offset/limit validation, and only complete results are
published. Unsupported output lengths, invalid native slices and overlapping
input/output storage return InvalidInput without modifying storage. No input bytes are owned by
the interface. PCRE2 match storage may retain the last subject address internally;
no operation reads it after find returns.

Ceilings: 16 KiB pattern, 1 MiB subject, 64 capture pairs including group zero,
32 live handles, 8 MiB charged native allocations per handle (including our
headers), nesting 64, match work 1,000,000 and depth 1,000. Options can lower
subject, native allocation, work and depth limits. Allocator quotas bound live
requested storage, not libc overhead or process RSS. Pattern length/nesting and
allocation limits do not establish a compile-time deadline. PCRE2 work limits
reset for candidate start positions: they are not total-operation deadlines.

find accepts start offsets including subject length. Empty matches are valid.
Iteration is caller-driven and must bound call counts. Advancing one byte after
an empty match skips nonempty alternatives at the same position. No automatic
iterator, replacement, named lookup, serialization, locale mutation or callbacks
are exposed in this first version.

Tests must cover malformed/binary inputs, captures, bounds, stale aliases,
allocation failures and recovery, concurrency, debug/optimized Goose builds,
independent common-syntax Python fixtures, native sanitizers and bounded fuzzing.
Benchmarks retain raw samples and source/toolchain/backend identities; no speed
claims follow from smoke execution alone.
