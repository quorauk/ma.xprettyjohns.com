all: build

clean:
	rm -rf public

build: clean
	hugo -b https://ma.xprettyjohns.com/
