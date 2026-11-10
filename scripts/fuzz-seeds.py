#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
import argparse
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--corpus', type=Path,
                    default=Path(__file__).resolve().parents[1] / '.build/corpus')
root = parser.parse_args().corpus
root.mkdir(parents=True, exist_ok=True)
for index, (pattern, subject) in enumerate([
    (b'(a+)(b)?', b'xxaaa'), (b'(?=(ab))a', b'ab'),
    (b'(*NO_START_OPT)(a+)+$', b'a' * 40 + b'!'),
    (b'(*UTF)x', b'x'), (b'(*UCP)x', b'x'),
    (b'(a|(b))+', b'aba'), (b'(', b''), (b'\x00\xff', b'x\x00\xff'),
    (b'(' * 65 + b'a' + b')' * 65, b'a'),
    (b'a{65535}', b'a'), (b'a' * 16385, b'a'),
    (b'', b''), (b'(a*)*', b'bbb'), (b'(?<=a)b', b'ab'),
]):
    # Two big-endian split bytes, then pattern bytes and subject bytes.
    (root / f'seed-{index}').write_bytes(len(pattern).to_bytes(2, 'big') + pattern + subject)
