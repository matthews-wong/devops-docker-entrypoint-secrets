.PHONY: validate lint test

validate: lint test

lint:
	shellcheck entrypoint.sh examples/serve.sh tests/test_entrypoint.sh
	hadolint Dockerfile

test:
	sh tests/test_entrypoint.sh
