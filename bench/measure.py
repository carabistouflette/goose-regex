#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Retain raw process timings for five byte-regex workloads; no speed assertions."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]


def capture(*args):
    return subprocess.check_output(args, text=True).strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--goose', required=True)
    parser.add_argument('--runs', type=int, default=7)
    parser.add_argument('--output', default='.build/benchmark.json')
    options = parser.parse_args()
    if not 1 <= options.runs <= 100:
        parser.error('runs must be 1..100')
    os.chdir(ROOT)
    binary = ROOT / '.build/bench'
    binary.parent.mkdir(exist_ok=True)
    subprocess.run([options.goose, 'build', 'bench/bench.goose', '--standalone', '-O2', '--cc', 'cc', '-o', str(binary)], check=True)
    workloads = {'diagnostic': (10000, 440000), 'large': (128, 33554432),
                 'no-match': (128, 0), 'captures': (10000, 320000), 'hostile': (1000, 1000)}
    cases = [(workload, mode) for workload in workloads for mode in ('reuse', 'compile')]
    samples = {f'{workload}.{mode}': [] for workload, mode in cases}
    for workload, mode in cases:
        subprocess.run([str(binary), mode, workload], check=True, stdout=subprocess.DEVNULL)
    for index in range(options.runs):
        for workload, mode in (cases if index % 2 == 0 else list(reversed(cases))):
            start = time.perf_counter_ns()
            result = subprocess.check_output([str(binary), mode, workload], text=True).strip()
            elapsed = time.perf_counter_ns() - start
            if result != str(workloads[workload][1]):
                raise RuntimeError(f'unexpected checksum for {workload}: {result}')
            samples[f'{workload}.{mode}'].append(elapsed)
    paths = ['regex.goose', 'regex.build', 'CMakeLists.txt', 'native/regex.c', 'native/regex.h', 'bench/bench.goose', 'bench/measure.py']
    report = {'head': capture('git', 'rev-parse', 'HEAD'),
              'dirty': bool(capture('git', 'status', '--porcelain', '--untracked-files=no')),
              'files_sha256': {p: hashlib.sha256(Path(p).read_bytes()).hexdigest() for p in paths},
              'compiler_pin': Path('GOOSE_REVISION').read_text().strip(),
              'goose_sha256': hashlib.sha256(Path(options.goose).read_bytes()).hexdigest(),
              'binary_sha256': hashlib.sha256(binary.read_bytes()).hexdigest(),
              'cc': capture('cc', '--version'), 'pcre2': capture('pkg-config', '--modversion', 'libpcre2-8'),
              'platform': platform.platform(), 'cpu': platform.processor(),
              'affinity': sorted(os.sched_getaffinity(0)),
              'workloads': {key: {'iterations': value[0], 'checksum': value[1]} for key, value in workloads.items()}, 'samples_ns': samples,
              'limits': 'Process startup included; five fixed fixtures; shared host; no cross-library or general speed claim.'}
    Path(options.output).parent.mkdir(parents=True, exist_ok=True)
    Path(options.output).write_text(json.dumps(report, indent=2) + '\n')
    print(options.output)


if __name__ == '__main__':
    main()
