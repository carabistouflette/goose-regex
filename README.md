# goose-regex

Reusable byte regular expressions for [Goose](https://github.com/aardappel/goose),
using PCRE2's 8-bit interpreter. Apache-2.0. Experimental alpha interface; publication candidate for `v0.1.0-alpha.1`.

Compile once, search repeatedly, and copy capture offsets into caller storage.
Pattern and input bytes can contain NUL. UTF/UCP activation is disabled. No JIT,
replacement, automatic iterator, named-capture lookup or serialization.

## Build and try

Requires CMake 3.27+, a C/C++20 toolchain for Goose, pkg-config, PCRE2 10.42+
development files, Make, Python 3.11+, Git and POSIX threads. On Debian/Ubuntu:
`sudo apt-get install build-essential cmake pkg-config libpcre2-dev python3 git`.
Clang is additionally needed for fuzzing. Linux x86-64 is the initially tested
platform; other platforms are unqualified.

Clone the standalone repository:

```sh
git clone https://github.com/carabistouflette/goose-regex.git
cd goose-regex
```

Then:

```sh
make setup
make check test test-debug
.toolchain/goose/build/goose run examples/diagnostics.goose
```

`make setup` fetches and builds the exact upstream commit in GOOSE_REVISION.
An existing matching compiler can be supplied with `GOOSE=/absolute/path/to/goose`.
Native source fingerprints invalidate Goose's package cache; `make format`
refreshes them and `make check` rejects stale fingerprints. This fingerprint
covers repository sources, not the installed PCRE2. After changing PCRE2 paths,
versions or linkage, rebuild with a fresh `GOOSE_HOME` directory; otherwise Goose
can reuse a package built against a previous backend.

## Example

```goose
import regex from "./path/to/goose-regex";
import std;
fn main() {
    let options = regex::Options { .. };
    let pattern, compiled = regex::compile("([a-z]+)=([0-9]+)", options);
    assert(compiled.error == regex::Error.None);
    var offsets: i64[6] = [-1; 6];
    let result = regex::find(pattern, "count=42", 0, offsets);
    assert(result.error == regex::Error.None && result.matched);
    assert(offsets == [0, 8, 0, 5, 6, 8]);
    assert(regex::close(pattern) == regex::Error.None);
}
```

## Interface and ownership

- `compile(bytes, options)` returns `Pattern, Status`. Success gives a positive
  token and `pattern.pairs` including capture zero. Failure gives a zero token.
  Syntax errors include a PCRE2 code and byte error offset (otherwise -1).
- `find(pattern, subject, start, offsets)` returns `Status`. Start is a byte offset
  in 0..subject.len inclusive. Supply at least `2*pattern.pairs` and at most 128
  integers. Each pair is a half-open byte span; unmatched groups are -1,-1.
  Lookaround captures can extend outside capture zero. `matched=false` with
  `error=None` means no match. `pairs` is zero unless a match succeeds.
- `close(pattern)` returns `Error`. Call once for every successful compile,
  including after later search failures. Copies alias the resource; closing
  invalidates every copy. Invalid, stale and already-closed tokens are rejected. Tokens are predictable
  process-local identifiers, not security capabilities.
  Do not persist tokens or modify handle fields. The native token is authoritative;
  modifying `pairs` does not change required output capacity.

For structurally valid buffers, find fills all offsets with -1 before validating
handle, start or limits. Unsupported lengths, overlapping input/output storage,
or invalid native slices return InvalidInput without modifying storage. Output
slices must not alias the subject. No captures are published after a search error.
Capture offsets remain valid values after close; they do not own input bytes.

Errors distinguish InvalidInput, InvalidHandle, InvalidPattern, LimitExceeded,
OutOfMemory, BackendFailure and Busy. `backend_code` is diagnostic only and can
vary with the installed PCRE2. Busy means another operation owns the same handle;
no automatic waiting or retry occurs. Unrelated handles run independently.

## Bounds and semantics

| Resource | Ceiling/default |
| --- | --- |
| Pattern bytes | 16,384 |
| Input bytes (`input_limit`) | 1,048,576; may be lowered to zero |
| Capture pairs, including whole match | 64 |
| Simultaneous live handles | 32 per linked native instance |
| Native outstanding bytes per handle (`memory_limit`) | 8,388,608; may be lowered to 1 |
| PCRE2 match work (`work_limit`) | 1,000,000; may be lowered to 1 |
| PCRE2 match depth (`depth_limit`) | 1,000; may be lowered to 1 |
| Pattern parenthesis nesting | 64 |

The allocation quota covers PCRE2 contexts, code, reusable match workspace and
our allocation headers. It excludes libc metadata, library internals outside the
PCRE2 allocation callbacks and process RSS. Quota exhaustion is LimitExceeded;
system allocation failure is OutOfMemory. Warm searches reuse retained storage;
a search requiring deeper frames can allocate up to the remaining quota.

PCRE2 work counters reset for each candidate starting position. These limits
are **not wall-clock or total-operation deadlines**. Pattern bounds do not give
a compilation deadline either. Applications requiring hard deadlines should use
an externally supervised process. Inline pattern controls may lower limits.
The default newline is LF and backslash-R convention ANYCRLF; PCRE2 inline
controls can override these. Default byte character tables are used, without
application locale changes. PCRE2 syntax and behavior can vary across versions.

Empty matches are valid, including at the end of input. Iteration is explicitly
caller-driven: bound your call count and decide how to progress. Advancing one
byte after an empty match skips nonempty alternatives at that same position.
There is no hidden iteration/retry policy. Input need only live during find;
PCRE2 internally retains a subject address in match storage but this interface
never accesses it after return or exposes it.

## Validation and performance

```sh
make native
make test-minimum
make sanitize CC=clang
make sanitize CC=gcc
make fuzz FUZZ_RUNS=10000
make bench GOOSE=/absolute/path/to/goose
```

Tests include independent Python `re` comparison on shared byte syntax, Goose
boundary/ownership checks, allocation-site injection, stale tokens, binary data,
unaligned ABI output and threaded lifecycle stress. Sanitizers instrument this
wrapper, not the system PCRE2 binary. Fuzzing is a bounded smoke campaign, not an
audit. See [validation](VALIDATION.md), [benchmark instructions](bench/README.md),
[design](DESIGN.md), [contributing](CONTRIBUTING.md), and [security](SECURITY.md).
