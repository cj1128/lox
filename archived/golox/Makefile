install:
	@go install
.PHONY: install

run: install
	@golox
.PHONY: run

test:
	@go test -cover
.PHONY: test

lint:
	@gometalinter --config=.gometalinterrc
.PHONY: lint
