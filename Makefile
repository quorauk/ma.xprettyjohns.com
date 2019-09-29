all: build

clean:
		rm -rf docs/*

build: clean docs/CNAME
		hugo -b https://ma.xprettyjohns.com/ -d docs

docs/CNAME:
		echo -n ma.xprettyjohns.com > docs/CNAME

package: build
		tar -czf ma.xprettyjohns.com.tgz docs
