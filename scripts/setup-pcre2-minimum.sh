#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
cd "$(dirname "$0")/.."
root="$PWD/.build/pcre2-10.42"
mkdir -p "$root"
if [[ ! -f "$root/source.tar.bz2" ]]; then
    curl --fail --location --silent --show-error \
      https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.42/pcre2-10.42.tar.bz2 \
      -o "$root/source.tar.bz2"
fi
printf '%s  %s\n' 8d36cd8cb6ea2a4c2bb358ff6411b0c788633a2a45dabbf1aeb4b701d1b5e840 "$root/source.tar.bz2" | sha256sum --check
if [[ ! -d "$root/pcre2-10.42" ]]; then tar -xjf "$root/source.tar.bz2" -C "$root"; fi
cmake -S "$root/pcre2-10.42" -B "$root/build" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DCMAKE_INSTALL_PREFIX="$root/install" -DCMAKE_INSTALL_LIBDIR=lib \
  -DBUILD_SHARED_LIBS=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DPCRE2_BUILD_PCRE2GREP=OFF -DPCRE2_BUILD_TESTS=OFF
cmake --build "$root/build" --parallel "${JOBS:-2}"
cmake --install "$root/build"
