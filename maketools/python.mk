ifeq ($(wildcard requirements.txt),requirements.txt)
ifneq ($(shell grep mypy requirements.txt --count),0)
test::
	$(run) mypy --install-types
endif
endif

.PHONY: test
test:: image # Runs pytest in the environment
	$(run) pytest
