---
title: "Deploying Hugo with Travis CI"
date: 2019-06-29T01:56:15+01:00
---

This blog is built with Hugo, and I wanted a simple way to build and then deploy it with Ansible. To do this I used Travis CI, this is relatively simple, but isn't documented very well. So Here I'll show you how I did it.

First up, you want a Hugo site, get started [here](https://gohugo.io). One simple thing that may immediately break in Travis is themes as submodules. Travis can't deal with ssh submodules, so check your .gitmodules file for ssh urls, and replace them with https if possible.

Next, you will want to setup your build and package pipeline. I like using a Makefile for this, but feel free to use what you are comfortable with.

{{< highlight make "linenos=table" >}}
all: build

clean:
		rm -rf public

build: clean
		hugo -b https://ma.xprettyjohns.com/

package: build
		tar -czf ma.xprettyjohns.com.tgz public
{{</ highlight >}}

Essentially, the makefile will build the static hugo files to the ./public directory, then the package it into a tgz file for deployment. Now we need to get TravisCI to run this Makefile as part of the CI process. Create the following travis.yml file in the root of your repository.

{{< highlight yaml "linenos=table" >}}
language: go
install:
- mkdir -p $HOME/bin
- wget https://github.com/gohugoio/hugo/releases/download/v0.55.6/hugo_0.55.6_Linux-64bit.tar.gz
  -O /tmp/hugo.tar.gz
- tar -xzf /tmp/hugo.tar.gz -C $HOME/bin/
- export PATH=$PATH:$HOME/bin
script: make package
{{</ highlight >}}

This downloads the Hugo binary, adds it to the path, and then runs the Makefile package script. Now we want to set up deployment. 

{{< highlight sh "linenos=table" >}}
# install travis cli
gem install travis
# login to travisci.com
travis login --pro
# setup releases, follow the instructions
travis setup releases -r quorauk/ma.xprettyjohns.com --pro
{{</ highlight >}}

The last step is setting deploy.skip_cleanup: true, so that your deployment artifact isn't deleted before the deployment step. Set the branch you want to deploy from (probably master), and set on.tags: true. Your final travis.yml should look like this.

{{< highlight yaml "linenos=table" >}}
language: go
install:
- mkdir -p $HOME/bin
- wget https://github.com/gohugoio/hugo/releases/download/v0.55.6/hugo_0.55.6_Linux-64bit.tar.gz
  -O /tmp/hugo.tar.gz
- tar -xzf /tmp/hugo.tar.gz -C $HOME/bin/
- export PATH=$PATH:$HOME/bin
script: make package
deploy:
  provider: releases
  api_key:
    secure: J1eoJrlUvDICgDDHa6jefQnsftDUFwRecIlieFvcllamm5ornBMzvz9tNXW4Ro2msDFtHZzVVPY08s3DVs5xjWvnp8We5qiUv4AT0kydSRfqmUfN7yuj5F+OrY5lpyCuJzBQ3yeHVqbr3EUnFtOdaKRRYEZmQgVZLR5EHn6tC1iQBrgwU1F2c+y8tFCDwLvj+osXarcn9Jxbo30FHEMgT6wIvgi/rqMszoGmtM76n62iHbrkTP8S35DYPzMVc6DG4GvS+K2FVbj4L4UUmR4dcn83/yfJehSnsDVZ8/Clc0p1A/JC7FRwzEFJ6p7hWRFg9HKo4+Rg9JWHpAwQmzwEaRngh7e2FFGu/SFrLkp35OitUPyK7308okJPQw+rol3ex4qV/tPAEVxAGh1potH1opqEg6rnpIpTWQ1Uxaxccm31OArzof9P96VoY8HK9xaP7ohrb+eSekmp9ZJyb7TDiYlgnyH1KdryYlRn34Z0jMqnLOwmo8ajimN6GiwMOy8Ng5w/ac5vjpirps8Ky4MRTA99KgPlXExgzh2YMD1XzAn7ovsgCreqBBSTaVzFeLm9DdkGVXnO6yciqUk3E7WPWgGx6OfnEpDc0xz1YWfWuz6RDPDK/83OMk/9znZA7u91Tj41qDybK7nfg+Y2ZA06doULFnZgaPq7Xv6/D5OEHMk=
  file: ma.xprettyjohns.com.tgz
  skip_cleanup: true
  on:
    repo: quorauk/ma.xprettyjohns.com
    tags: true
    branch: master
{{</ highlight >}}
