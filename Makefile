FPC ?= fpc
FPCFLAGS ?= -Mobjfpc -Sh -O2 -XX -Xs -CX
PREFIX ?= /usr/local
DESTDIR ?=
INSTALL_ROOKCC ?= 0
# Optional compiler-host optimization build; normal releases use the reproducible default flags.
OPTIMIZED_FPCFLAGS ?= -Mobjfpc -Sh -O3 -Si -XX -Xs -CX

BUILD_DIR := build
UNIT_DIR := $(BUILD_DIR)/units
OPTIMIZED_UNIT_DIR := $(BUILD_DIR)/units-optimized
BIN := $(BUILD_DIR)/rcc
NATIVE_DRIVER_TEST_UNIT_DIR := $(BUILD_DIR)/units-native-driver-test
NATIVE_DRIVER_TEST_BIN := $(BUILD_DIR)/rcc-native-driver-test
SOURCES := $(wildcard src/*.pas)
RESOURCE_DIR := $(DESTDIR)$(PREFIX)/share/rcc
DOC_DIR := $(DESTDIR)$(PREFIX)/share/doc/rcc
RELEASE_VERSION := $(shell tr -d '\r\n' < VERSION)

.PHONY: all optimized test test-platform-support test-target-formats \
	test-native-driver test-native-host test-c-differential \
	test-cross-differential test-cross-execution test-cross-abi-interop \
	test-semantic-conversions test-release-hardening test-standard-modes \
	test-parser-fuzz test-determinism test-examples test-posix-headers \
	test-source-integrity bench bench-quick package package-check release-gate \
	install install-rookcc uninstall clean

all: $(BIN)

optimized:
	@mkdir -p "$(BUILD_DIR)"
	@rm -rf "$(OPTIMIZED_UNIT_DIR)"
	@mkdir -p "$(OPTIMIZED_UNIT_DIR)"
	$(FPC) $(OPTIMIZED_FPCFLAGS) -Fu./src -FU"$(OPTIMIZED_UNIT_DIR)" \
		-FE"$(BUILD_DIR)" -o"$(abspath $(BIN))" src/rcc.pas
	@printf 'optimized rcc: %s (%s bytes)\n' "$(BIN)" \
		"$$(wc -c < "$(BIN)")"

test: test-source-integrity test-platform-support \
	test-release-hardening test-standard-modes \
	test-semantic-conversions test-c-differential test-cross-differential \
	test-cross-execution test-cross-abi-interop test-parser-fuzz \
	test-determinism test-examples test-posix-headers

test-platform-support: test-target-formats test-native-driver test-native-host

test-c-differential: $(BIN)
	python3 tests/c_differential.py "$(abspath $(BIN))"


test-cross-differential: $(BIN)
	python3 tests/cross_differential.py "$(abspath $(BIN))"

test-cross-execution: $(BIN)
	python3 tests/cross_execution.py "$(abspath $(BIN))"

test-cross-abi-interop: $(BIN)
	python3 tests/cross_abi_interop.py "$(abspath $(BIN))"

test-semantic-conversions: $(BIN)
	python3 tests/semantic_conversions.py "$(abspath $(BIN))"

test-release-hardening: $(BIN)
	python3 tests/release_hardening.py "$(abspath $(BIN))"

test-standard-modes: $(BIN)
	python3 tests/standard_modes.py "$(abspath $(BIN))"

test-parser-fuzz: $(BIN)
	python3 tests/parser_fuzz.py "$(abspath $(BIN))"

test-source-integrity:
	python3 tests/source_integrity.py

test-determinism: $(BIN)
	python3 tests/determinism.py "$(abspath $(BIN))"

test-examples: $(BIN)
	python3 tests/examples_smoke.py "$(abspath $(BIN))"


test-posix-headers: $(BIN)
	python3 tests/posix_headers.py "$(abspath $(BIN))"

test-target-formats: $(BIN)
	python3 tests/target_format_matrix.py "$(abspath $(BIN))" \
		"$(abspath $(BUILD_DIR))/target-format-tests"

test-native-driver: $(NATIVE_DRIVER_TEST_BIN)
	python3 tests/native_linker_driver_contract.py \
		"$(abspath $(NATIVE_DRIVER_TEST_BIN))"

test-native-host: $(BIN)
	python3 tests/native_host_smoke.py "$(abspath $(BIN))"

$(NATIVE_DRIVER_TEST_BIN): $(SOURCES) VERSION
	@mkdir -p "$(BUILD_DIR)" "$(NATIVE_DRIVER_TEST_UNIT_DIR)"
	$(FPC) $(FPCFLAGS) -dRCC_DRIVER_TESTING -Fu./src \
		-FU"$(NATIVE_DRIVER_TEST_UNIT_DIR)" -FE"$(BUILD_DIR)" \
		-o"$(abspath $(NATIVE_DRIVER_TEST_BIN))" src/rcc.pas

$(BIN): $(SOURCES) VERSION
	@mkdir -p "$(BUILD_DIR)" "$(UNIT_DIR)"
	$(FPC) $(FPCFLAGS) -Fu./src -FU"$(UNIT_DIR)" -FE"$(BUILD_DIR)" \
		-o"$(abspath $(BIN))" src/rcc.pas

bench: $(BIN)
	@mkdir -p dist/benchmarks
	python3 bench/compare.py --rcc "$(abspath $(BIN))" \
		--json-out "dist/benchmarks/rcc-$(RELEASE_VERSION).json" \
		--csv-out "dist/benchmarks/rcc-$(RELEASE_VERSION).csv" \
		--markdown-out "dist/benchmarks/rcc-$(RELEASE_VERSION).md"

bench-quick: $(BIN)
	@mkdir -p dist/benchmarks
	python3 bench/compare.py --rcc "$(abspath $(BIN))" \
		--compile-runs 1 --runtime-runs 1 \
		--json-out "dist/benchmarks/rcc-$(RELEASE_VERSION)-quick.json" \
		--markdown-out "dist/benchmarks/rcc-$(RELEASE_VERSION)-quick.md"

package:
	./scripts/package.sh

package-check:
	./scripts/package_test.sh

release-gate:
	./scripts/release_gate.sh

install: $(BIN)
	install -d "$(DESTDIR)$(PREFIX)/bin"
	install -m755 "$(BIN)" "$(DESTDIR)$(PREFIX)/bin/rcc"
	install -d "$(RESOURCE_DIR)"
	install -m644 VERSION "$(RESOURCE_DIR)/VERSION"
	install -d "$(RESOURCE_DIR)/include"
	cp -a include/. "$(RESOURCE_DIR)/include/"
	find "$(RESOURCE_DIR)/include" -type f -exec chmod 0644 {} +
	install -d "$(DESTDIR)$(PREFIX)/share/man/man1"
	install -m644 man/rcc.1 "$(DESTDIR)$(PREFIX)/share/man/man1/rcc.1"
	install -d "$(DESTDIR)$(PREFIX)/share/zsh/site-functions"
	install -m644 completions/_rcc "$(DESTDIR)$(PREFIX)/share/zsh/site-functions/_rcc"
	install -d "$(DESTDIR)$(PREFIX)/share/bash-completion/completions"
	install -m644 completions/rcc.bash "$(DESTDIR)$(PREFIX)/share/bash-completion/completions/rcc"
	install -d "$(DESTDIR)$(PREFIX)/share/fish/vendor_completions.d"
	install -m644 completions/rcc.fish "$(DESTDIR)$(PREFIX)/share/fish/vendor_completions.d/rcc.fish"
	install -d "$(DOC_DIR)"
	@for doc in README.md LICENSE RELEASE_HARDENING.md \
	  "RELEASE_NOTES_$(RELEASE_VERSION).md" \
	  "VERIFICATION_$(RELEASE_VERSION).md" \
	  "COMPATIBILITY_$(RELEASE_VERSION).md"; do \
	  if [ -f "$$doc" ]; then install -m644 "$$doc" "$(DOC_DIR)/"; fi; \
	done
	@if [ "$(INSTALL_ROOKCC)" = "1" ]; then \
	  $(MAKE) --no-print-directory install-rookcc; \
	fi
	@printf 'installed native rcc to %s\n' "$(DESTDIR)$(PREFIX)/bin/rcc"

install-rookcc:
	@set -eu; \
	dir="$(DESTDIR)$(PREFIX)/bin"; alias_path="$$dir/rookcc"; \
	mkdir -p "$$dir"; \
	if [ -e "$$alias_path" ] || [ -L "$$alias_path" ]; then \
	  target=$$(readlink "$$alias_path" 2>/dev/null || true); \
	  if [ "$$target" != "rcc" ]; then \
	    printf 'error: refusing to replace existing %s\n' "$$alias_path" >&2; \
	    exit 1; \
	  fi; \
	else \
	  ln -s rcc "$$alias_path"; \
	fi; \
	printf 'installed rookcc alias at %s\n' "$$alias_path"

uninstall:
	rm -f "$(DESTDIR)$(PREFIX)/bin/rcc"
	@if [ "$$(readlink "$(DESTDIR)$(PREFIX)/bin/rookcc" 2>/dev/null || true)" = "rcc" ]; then \
	  rm -f "$(DESTDIR)$(PREFIX)/bin/rookcc"; \
	fi
	rm -f "$(DESTDIR)$(PREFIX)/share/man/man1/rcc.1"
	rm -f "$(DESTDIR)$(PREFIX)/share/zsh/site-functions/_rcc"
	rm -f "$(DESTDIR)$(PREFIX)/share/bash-completion/completions/rcc"
	rm -f "$(DESTDIR)$(PREFIX)/share/fish/vendor_completions.d/rcc.fish"
	rm -rf "$(RESOURCE_DIR)" "$(DOC_DIR)"

clean:
	rm -rf "$(BUILD_DIR)"

	rm -f src/*.ppu src/*.o
