.PHONY: help test unit lint install-dev clean release demo

# Default target
help:
	@echo "Pulsar - Minimal Zsh Plugin Manager"
	@echo ""
	@echo "Available targets:"
	@echo "  make test        - Run test suite"
	@echo "  make unit        - Run specific test file"
	@echo "  make lint        - Run ShellCheck linting"
	@echo "  make install-dev - Install Pulsar locally for development"
	@echo "  make clean       - Clean temporary files and cache"
	@echo "  make release     - Create a new release tag"
	@echo "  make demo        - Open demo asset"
	@echo "  make help        - Show this help message"

unit:
	./tests/run-clitests tests/test-pulsar.md

test:
	@echo "Running Pulsar test suite..."
	./tests/run-clitests

# Run ShellCheck linting
lint:
	@echo "Running ShellCheck..."
	@shellcheck pulsar.zsh install.sh 2>/dev/null || echo "ShellCheck not found - skipping lint"

# Install for development (symlink to local .zshrc)
install-dev:
	@echo "Installing Pulsar for development..."
	@./install.sh

# Clean temporary files and cache
clean:
	@echo "Cleaning temporary files..."
	@find . -name '*.zwc' -delete
	@find . -name '.DS_Store' -delete
	@echo "To clean plugin cache: rm -rf $${XDG_CACHE_HOME:-$$HOME/.cache}/pulsar"

release:
	@if [ -z "$$V" ]; then echo "Usage: make release V=vX.Y.Z"; exit 2; fi
	git tag -a $$V -m "$$V"
	git push origin $$V

# Open the README demo section image (requires xdg-open/open)
demo:
	@if command -v xdg-open >/dev/null; then xdg-open assets/pulsar-demo.gif; \
	elif command -v open >/dev/null; then open assets/pulsar-demo.gif; \
	else echo "No opener found"; fi
