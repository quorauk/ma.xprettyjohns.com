all: build

clean:
		rm -rf docs/*

build: clean
		hugo -b https://ma.xprettyjohns.com/ -d docs

package: build
		tar -czf ma.xprettyjohns.com.tgz public
