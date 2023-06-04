# libduckdb-docker

DuckDB headers and libs distributed as Docker images, built with Ruby projects
in mind but might be helpful for other platforms as well.

Main use case it to support a project that depends on [suketa/ruby-duckdb](https://github.com/suketa/ruby-duckdb).

Curious why I built this? Skip to the [why](#why) section below.

## Available tags

https://hub.docker.com/r/fgrehm/libduckdb/tags

## Usage

On your `Dockerfile`s:

```dockerfile
FROM fgrehm/libduckdb:<TAG> AS libduckdb

FROM some/base:image-tag

# One line if you trust me
COPY --from=libduckdb /libduckdb /

# Or place files in the right directory explicitly
COPY --from=libduckdb /libduckdb/usr/local/include/duckdb.h /usr/local/include
COPY --from=libduckdb /libduckdb/usr/local/lib/libduckdb.so /usr/local/lib
```

### Alpine Linux

```dockerfile
FROM fgrehm/libduckdb:0.8.0-alpine3.18 AS libduckdb

FROM ruby:3.2-alpine3.18
RUN apk add --no-cache --update \
            make \
            g++

# Only if you trust me
COPY --from=libduckdb /libduckdb /

# On a real project you'd add your Gemfile, bundle install, etc.
RUN gem install duckdb
```

### Other distros

```dockerfile
FROM fgrehm/libduckdb:0.8.0 AS libduckdb

FROM ruby:3-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends make gcc \
    && rm -rf /var/lib/apt/lists/*

# Only if you trust me
COPY --from=libduckdb /libduckdb /

# On a real project you'd add your Gemfile, bundle install, etc.
RUN gem install duckdb
```

## Why?

In order to use DuckDB on Ruby with [suketa/ruby-duckdb](https://github.com/suketa/ruby-duckdb)
you need to install the DuckDB engine or you'll get an error like this one:

```
=> gem install duckdb

...

********************************************************************************
duckdb >= 0.5.0 is not found. Install duckdb >= 0.5.0 library and header file.
********************************************************************************
```

On MacOS you should be a [`brew install duckdb`](https://github.com/suketa/ruby-duckdb#pre-requisite-setup-macos)
away from fixing that and getting the gem to be built.

On Linux machines you'll need to [download the latest C++ package release for DuckDB](https://github.com/suketa/ruby-duckdb#pre-requisite-setup-linux)
and make it available for use by Ruby. In `Dockerfile` terms, this should do
the trick:

```dockerfile
FROM ruby:3
ARG DUCKDB_VERSION=0.8.0
RUN wget https://github.com/duckdb/duckdb/releases/download/v${DUCKDB_VERSION}/libduckdb-linux-amd64.zip \
    && unzip libduckdb-linux-amd64.zip -d libduckdb \
    && mv libduckdb/duckdb.* /usr/local/include \
    && mv libduckdb/libduckdb.so /usr/local/lib \
    && rm -rf libduckd *.zip

# On a real project you'd add your Gemfile, bundle install, etc.
RUN gem install duckdb
```

In case you're using smaller images like `slim` variants or Alpine, you need a
few more things and your `Dockerfile` might look like this:

```dockerfile
FROM ruby:3-slim
ARG DUCKDB_VERSION=0.8.0
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
                       make \
                       gcc \
                       wget \
                       unzip \
    && rm -rf /var/lib/apt/lists/* \
    && wget https://github.com/duckdb/duckdb/releases/download/v${DUCKDB_VERSION}/libduckdb-linux-amd64.zip \
    && unzip libduckdb-linux-amd64.zip -d libduckdb \
    && mv libduckdb/duckdb.* /usr/local/include \
    && mv libduckdb/libduckdb.so /usr/local/lib \
    && rm -rf libduckd *.zip

# On a real project you'd add your Gemfile, bundle install, etc.
RUN gem install duckdb
```

Unfortunately the equivalent of that for Alpine Linux won't work:

```dockerfile
FROM ruby:3-alpine
ARG DUCKDB_VERSION=0.8.0

RUN apk add --update --no-cache make g++ unzip \
    && wget https://github.com/duckdb/duckdb/releases/download/v${DUCKDB_VERSION}/libduckdb-linux-amd64.zip \
    && unzip libduckdb-linux-amd64.zip -d libduckdb \
    && mv libduckdb/duckdb.* /usr/local/include \
    && mv libduckdb/libduckdb.so /usr/local/lib \
    && rm -rf libduckd *.zip

RUN gem install duckdb
```

You'll most likely get the error mentioned at the top of this section:

```
Building native extensions. This could take a while...
ERROR:  Error installing duckdb:
       ERROR: Failed to build gem native extension.

    current directory: /usr/local/bundle/gems/duckdb-0.8.0/ext/duckdb
/usr/local/bin/ruby extconf.rb
checking for duckdb.h... yes
checking for duckdb_pending_prepared() in duckdb.h... no
checking for duckdb_pending_prepared() in -lduckdb... no

...

********************************************************************************
duckdb >= 0.5.0 is not found. Install duckdb >= 0.5.0 library and header file.
********************************************************************************
```

If I'm not mistaken, the reason for that is because Alpine is based on
[musl](https://en.wikipedia.org/wiki/Musl) and even installing packages like
`gcompat` won't get it fixed. The solution is to compile the DuckDB library
yourself and that will take a good 20+min to complete (it takes 30min on
[GitHub actions](https://github.com/fgrehm/libduckdb-docker/actions)).

This project makes that precompiled library available for use on Docker images
using the `COPY` commands as described above, regardless of distribution flavor.
