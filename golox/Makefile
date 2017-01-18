.PHONY: install run

install:
	godep go install

run: install
	golox

lint:
	gometalinter --config=.gometalinterrc
