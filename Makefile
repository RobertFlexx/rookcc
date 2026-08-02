FPC ?= fpc
FPCFLAGS ?= -Mobjfpc -Sh -O2 -XX -Xs -CX
PREFIX ?= /usr/local
DESTDIR ?=
INSTALL_ROOKCC ?= 0

BUILD_DIR := build
UNIT_DIR := $(BUILD_DIR)/units
BIN := $(BUILD_DIR)/rcc
SOURCES := $(wildcard src/*.pas)
RESOURCE_DIR := $(DESTDIR)$(PREFIX)/share/rcc
DOC_DIR := $(DESTDIR)$(PREFIX)/share/doc/rcc

.PHONY: all install install-rookcc uninstall clean

all: $(BIN)

$(BIN): $(SOURCES) VERSION
	@mkdir -p "$(BUILD_DIR)" "$(UNIT_DIR)"
	$(FPC) $(FPCFLAGS) -Fu./src -FU"$(UNIT_DIR)" -FE"$(BUILD_DIR)" \
		-o"$(abspath $(BIN))" src/rcc.pas

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
	install -m644 README.md LICENSE "$(DOC_DIR)/"
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
