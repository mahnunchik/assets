
all: build

build:
	node_modules/.bin/coffee -cbo lib/ src/

clean:
	rm -rf lib/
	rm -rf ./assets
	rm -rf ./public
	rm -rf ./config

test: clean build
	node_modules/.bin/mocha --compilers coffee:coffee-script --reporter spec --globals NODE_CONFIG
