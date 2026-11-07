#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
from pathlib import Path
root = Path(__file__).resolve().parents[1] / '.build/corpus'
root.mkdir(parents=True, exist_ok=True)
for index, (pattern, subject) in enumerate([
    (b'(a+)(b)?', b'xxaaa'), (b'(?=(ab))a', b'ab'),
    (b'(*NO_START_OPT)(a+)+$', b'a' * 40 + b'!'),
    (b'(*UTF)x', b'x'), (b'(*UCP)x', b'x'),
    (b'(a|(b))+', b'aba'), (b'(', b''), (b'\x00\xff', b'x\x00\xff'),
    (b'', b''), (b'(a*)*', b'bbb'), (b'(?<=a)b', b'ab'),
]):
    # The fuzzer consumes one split byte, then pattern bytes, then subject bytes.
    (root / f'seed-{index}').write_bytes(bytes([len(pattern)]) + pattern + subject)
