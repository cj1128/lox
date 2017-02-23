install:
	godep go install
.PHONY: install

run: install
	golox
.PHONY: run

lint:
	gometalinter --config=.gometalinterrc
.PHONY: lint
