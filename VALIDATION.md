# Validation scope

The supported starting point is Linux x86-64, the exact Goose commit in
GOOSE_REVISION, and system PCRE2 >=10.42. The initial local run used PCRE2 10.49.
CI configuration is supplied but hosted CI has not run for this local repository.
There is no published release or public registration yet.

- `make check`: native fingerprint, Goose formatting and public source checks.
- `make test test-debug`: public Goose API/boundary tests, diagnostic consumer,
  standalone optimized/debug API and boundary binaries, native lifecycle tests and oracle.
- `make native`: allocation-failure injection at each allocation site reached by
  one compile fixture and first-search fixture, recovery, stale aliases, active
  handle limit, malformed/binary patterns, lookaround captures, unaligned output,
  eight-thread independent handle lifecycle stress.
- `make sanitize CC=clang` and `CC=gcc`: native tests under ASan/UBSan with leak
  detection. The separately installed PCRE2 binary is not instrumented.
- `make oracle`: Python re differential checks on 27 common byte-pattern fixtures
  and every valid start position (15,984 searches). This does not establish
  equivalence for all PCRE2 syntax or compare resource-limit behavior.
- `make fuzz`: Clang libFuzzer with ASan/UBSan, fixed seed, seeded binary/malformed/
  hostile-pattern corpus, maximum generated input 32,768 bytes and finite run
  count. Crash files land in the current directory; keep and regress failures.
- `make bench`: optimized standalone consumer, checksum checked, warmups and raw
  samples with source/backend/compiler identities. See bench/README.md.

These are finite checks. No sustained fuzzing, exhaustive allocation-site proof,
Windows/macOS qualification, hard deadline, portable implementation, cryptographic
security guarantee or universal performance claim is implied. Deterministic same-handle Busy and independent-handle stress tests are not a
complete concurrent schedule exploration. PCRE2's newer installed version can accept syntax absent
from 10.42. Version changes must be retested.

## Initial local evidence

Implementation commit `2adaa74bfb9f6ad88f63890215a947ed924d9116` passed public
Goose checks, debug/optimized execution, the 15,984-search oracle, GCC/Clang native
ASan/UBSan and 10,000 seeded libFuzzer executions. The exact benchmark fixture
and raw samples are retained in `bench/results/initial.json`; its recorded source
hashes identify the measured code. Documentation/test-target changes after that
commit do not alter those measured sources. There is no hosted CI result.

Two independent design reviews and three independent implementation reviews
covered ownership/resource limits, native safety, interface behavior and tests.
Findings led to a POSIX macro fix, a precise structural-invalid output contract,
search allocation/quota tests, deterministic same-handle Busy coverage, wider
fuzz framing and corrected token-security wording. Reviews and finite passing
tests are evidence, not an exhaustive security audit.
