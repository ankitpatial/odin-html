build:
	odin build ./src -o:speed -out:ohtml

build-example-ecomm:
	rm -rf ./out
	./ohtml generate ./examples/ecomm -o ./out
