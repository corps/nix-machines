.PHONY: test
test:: image # Runs pytest in the environment
	$(run) npm test
