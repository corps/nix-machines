.PHONY: format
format:: # invokes the code formatter
	make -C ../maketools image
	docker run --rm -v ./ /app maketools black /app


ifeq ($(wildcard requirements.txt),requirements.txt)
.PHONY: update
update:: # Updates development resources
	pip install -r requirements.txt
endif
