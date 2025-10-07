.PHONY: test unit release demo

unit:
	./tests/run-clitests tests/test-pulsar.md

test:
	./tests/run-clitests

release:
	@if [ -z "$$V" ]; then echo "Usage: make release V=vX.Y.Z"; exit 2; fi
	git tag -a $$V -m "$$V"
	git push origin $$V

# Open the README demo section image (requires xdg-open/open)
demo:
	@if command -v xdg-open >/dev/null; then xdg-open assets/pulsar-demo.gif; \
	elif command -v open >/dev/null; then open assets/pulsar-demo.gif; \
	else echo "No opener found"; fi
