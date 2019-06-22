all: build

clean:
		rm -rf public

build: clean
		hugo -b https://ma.xprettyjohns.com/

package: build
		tar -czf ma.xprettyjohns.com.tgz public
