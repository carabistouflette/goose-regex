# Security

This local experimental library has no public vulnerability-reporting endpoint
or supported release yet. Do not post exploit details in public issues. Before
publication, establish and verify private reporting for the public repository.

The native wrapper uses checked tokens, per-handle leases, quota-controlled
PCRE2 allocations, nesting/capture/input limits, byte matching and explicit
match work/depth limits. Copies alias resources; callers must close handles.
Native ABI callers must supply valid accessible memory: range checks cannot
prove pointer provenance or memory ownership. Invalid ABI pointers remain a
caller bug. Do not race access to the same caller buffers.

Match work limits are per candidate start, not deadlines. Bounds do not prevent
all expensive compilation or matching. Hard deadlines require process isolation.
Do not enable UTF/UCP by removing NEVER_UTF/NEVER_UCP without a new reviewed
contract. No user callbacks or JIT are exposed.

PCRE2 is a system dependency. Install security updates from your distributor.
Wrapper ASan/UBSan and bounded fuzz tests do not instrument the system library
and do not establish exhaustive safety. See README.md for exact limits.
