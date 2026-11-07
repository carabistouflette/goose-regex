#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Compare common byte-regex syntax with Python re, including every start offset."""
import ctypes as C
import itertools
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]


class Bytes(C.Structure):
    _fields_ = [("data", C.c_void_p), ("len", C.c_int64)]


class Ints(C.Structure):
    _fields_ = [("data", C.POINTER(C.c_int64)), ("len", C.c_int64)]


def byte_slice(data):
    storage = C.create_string_buffer(data)
    return storage, Bytes(C.cast(storage, C.c_void_p), len(data))


def ints(values):
    storage = (C.c_int64 * len(values))(*values)
    return storage, Ints(storage, len(values))


def main():
    output = ROOT / ".build" / "libregex-oracle.so"
    output.parent.mkdir(exist_ok=True)
    flags = subprocess.check_output(["pkg-config", "--cflags", "--libs", "libpcre2-8"], text=True).split()
    subprocess.run(["cc", "-std=c11", "-Wall", "-Wextra", "-Werror", "-shared", "-fPIC", "-O2",
                    str(ROOT / "native/regex.c"), "-pthread", *flags, "-o", str(output)], check=True)
    lib = C.CDLL(str(output))
    lib.gr_compile.argtypes = [Bytes, Ints, Ints]
    lib.gr_compile.restype = C.c_int64
    lib.gr_find.argtypes = [C.c_int64, Bytes, C.c_int64, Ints, Ints]
    lib.gr_find.restype = C.c_int64
    lib.gr_close.argtypes = [C.c_int64]
    lib.gr_close.restype = C.c_int64
    patterns = [b"", b"a", b"a*", b"a+?", b"a|ab", b"ab|a", b"(a)?(b*)", b"(a|(b))+",
                b"(a*)*", b"(?:ab){0,2}", b"^a", b"a$", b"(?m)^a$", b"(?s).+", b"[a-z]+",
                b"[^a]*", b"(a)?\\1", b"(?=a)", b"(?<=a)b", b"(?!b).", b"\\b[a-z]+\\b",
                b"\\d+", b"\\w*", b"\\s+", b"(\x00)(\xff)?", b"[\x80-\xff]+", b"(.)\\1"]
    subjects = {b"", b"abc", b"aaaab", b"aba", b"ab\nab\n", b" a1\t23\r\n", b"\x80\xff\x00a\xff",
                b"\x00\xff", b"aaaa", b"xyz", b"b\na\nb"}
    subjects.update(bytes(parts) for n in range(5) for parts in itertools.product(b"ab\x00", repeat=n))
    checks = 0
    for pattern in patterns:
        expected_pattern = re.compile(pattern)
        pattern_storage, pattern_slice = byte_slice(pattern)
        config, config_slice = ints([1048576, 8388608, 1000000, 1000])
        compiled, compiled_slice = ints([0, 0, 0, -1])
        assert lib.gr_compile(pattern_slice, config_slice, compiled_slice) == 0, pattern
        token, pairs = compiled[0], compiled[1]
        assert pairs == expected_pattern.groups + 1
        try:
            for subject in sorted(subjects):
                subject_storage, subject_slice = byte_slice(subject)
                for start in range(len(subject) + 1):
                    offsets, offsets_slice = ints([777] * (pairs * 2 + 2))
                    meta, meta_slice = ints([777] * 3)
                    rc = lib.gr_find(token, subject_slice, start, offsets_slice, meta_slice)
                    expected = expected_pattern.search(subject, start)
                    context = (pattern, subject, start, rc, list(meta), list(offsets))
                    assert rc == 0, context
                    assert bool(meta[0]) == (expected is not None), context
                    wanted = [-1] * len(offsets)
                    if expected is not None:
                        wanted[:pairs * 2] = [value for i in range(pairs) for value in expected.span(i)]
                        assert meta[1] == pairs, context
                    else:
                        assert meta[1] == 0, context
                    assert list(offsets) == wanted, (context, wanted)
                    checks += 1
        finally:
            assert lib.gr_close(token) == 0
    print(f"Python re differential: {checks} searches across {len(patterns)} patterns passed")


if __name__ == "__main__":
    main()
