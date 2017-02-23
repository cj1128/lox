install:
	godep go install
.PHONY: install

run: install
	golox
.PHONY: run

test:
	go test -v -cover
.PHONY: test

lint:
	gometalinter --config=.gometalinterrc
.PHONY: lint
