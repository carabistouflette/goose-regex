GOOSE ?= .toolchain/goose/build/goose
CC ?= cc
FUZZ_CC ?= clang
FUZZ_RUNS ?= 10000
CFLAGS = -std=c11 -Wall -Wextra -Werror -pthread
PCRE = $(shell pkg-config --cflags --libs libpcre2-8)
.PHONY: setup format check test test-debug native sanitize fuzz oracle bench
setup:
	./scripts/setup-goose.sh
format:
	python3 scripts/native-manifest.py
	"$(GOOSE)" format regex.goose tests examples bench
check:
	python3 scripts/native-manifest.py --check
	"$(GOOSE)" format --check regex.goose tests examples bench
	"$(GOOSE)" check tests/api.goose
	"$(GOOSE)" check tests/bounds.goose
	"$(GOOSE)" check bench/bench.goose
	"$(GOOSE)" check examples/diagnostics.goose
	git diff --check
test:
	"$(GOOSE)" run tests/api.goose
	"$(GOOSE)" run tests/bounds.goose
	"$(GOOSE)" run examples/diagnostics.goose
	mkdir -p .build
	"$(GOOSE)" build tests/api.goose --standalone -O2 --cc "$(CC)" -o .build/api
	./.build/api
	$(MAKE) native oracle
test-debug:
	"$(GOOSE)" run tests/api.goose --debug
	"$(GOOSE)" run tests/bounds.goose --debug
	mkdir -p .build
	"$(GOOSE)" build tests/api.goose --standalone --debug --cc "$(CC)" -o .build/api-debug
	./.build/api-debug
native:
	mkdir -p .build
	$(CC) $(CFLAGS) -DGR_TEST -O2 tests/native.c native/regex.c $(PCRE) -o .build/native
	./.build/native
sanitize:
	mkdir -p .build
	$(CC) $(CFLAGS) -DGR_TEST -O1 -g -fno-omit-frame-pointer -fsanitize=address,undefined tests/native.c native/regex.c $(PCRE) -o .build/sanitize-$(notdir $(CC))
	ASAN_OPTIONS=detect_leaks=1:abort_on_error=1 UBSAN_OPTIONS=halt_on_error=1 ./.build/sanitize-$(notdir $(CC))
fuzz:
	mkdir -p .build/corpus
	python3 scripts/fuzz-seeds.py
	$(FUZZ_CC) $(CFLAGS) -O1 -g -fsanitize=fuzzer,address,undefined tests/fuzz.c native/regex.c $(PCRE) -o .build/fuzz
	./.build/fuzz -runs=$(FUZZ_RUNS) -seed=491 -max_len=1024 -timeout=5 .build/corpus
oracle:
	mkdir -p .build
	python3 tests/oracle.py
bench:
	python3 bench/measure.py --goose "$(abspath $(GOOSE))"
