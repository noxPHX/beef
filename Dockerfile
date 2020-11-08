FROM ruby:latest AS builder

ARG BUNDLER_ARGS="--jobs=2" 

# Set gemrc config to install gems without Ruby Index (ri) and Ruby Documentation (rdoc) files
RUN echo "gem: --no-ri --no-rdoc" > /etc/gemrc

RUN apt-get update && \
    apt-get install -y musl-dev

WORKDIR /beef

COPY Gemfile .

RUN bundle install --system --gemfile=/beef/Gemfile $BUNDLER_ARGS && \
    rm -rf /usr/local/bundle/cache

# So we don't need to run as root
RUN find /usr/local/bundle -print0 | xargs -0 chmod a+r

FROM ruby:latest

# Use gemset created by the builder above
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Install BeEF's runtime dependencies
RUN apt-get update && \
    apt-get install -y curl git build-essential openssl libreadline6-dev zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev autoconf libc6-dev libncurses5-dev automake libtool bison nodejs libcurl4-openssl-dev gcc-8-base libgcc-8-dev

COPY . /beef

# Grant beef service account owner and groups rights over our BeEF working directory.
RUN groupadd -g 1000 beef && \
    useradd -r -u 1000 -g 1000 --create-home --home-dir /beef beef && \
    find /beef -print0 | xargs -0 chown beef:beef

WORKDIR /beef

# Ensure we are using our service account by default
USER beef

# Expose UI, Proxy, WebSocket server, and WebSocketSecure server
EXPOSE 3000 6789 61985 61986

ENTRYPOINT [ "/beef/beef" ]
