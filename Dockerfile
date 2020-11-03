###########################################################################################################
###########################################################################################################
##                                                                                                       ##
##   Please read the Wiki Installation section on set-up using Docker prior to building this container.  ##
##   BeEF does NOT allow authentication with default credentials. So please, at the very least           ##
##   change the username:password in the config.yaml file to something secure that is not beef:beef      ##
##   before building or you will to denied access and have to rebuild anyway.                            ##
##                                                                                                       ##
###########################################################################################################
###########################################################################################################

# ---------------------------- Start of Builder 0 - Gemset Build ------------------------------------------
FROM ruby:latest AS builder
LABEL maintainer="Beef Project: github.com/beefproject/beef"

# Install gems in parallel with 4 workers to expedite build process.=
ARG BUNDLER_ARGS="--jobs=4" 

# Set gemrc config to install gems without Ruby Index (ri) and Ruby Documentation (rdoc) files
RUN echo "gem: --no-ri --no-rdoc" > /etc/gemrc

COPY . /beef

# Add bundler/gem dependencies and then install 
RUN apt-get update && \
    apt-get install -y musl-dev && \
  bundle install --system --gemfile=/beef/Gemfile $BUNDLER_ARGS && \
  # Temp fix for https://github.com/bundler/bundler/issues/6680
  rm -rf /usr/local/bundle/cache

WORKDIR /beef

# So we don't need to run as root
RUN chmod -R a+r /usr/local/bundle
# ------------------------------------- End of Builder 0 -------------------------------------------------


# ---------------------------- Start of Builder 1 - Final Build ------------------------------------------
FROM ruby:latest
LABEL maintainer="Beef Project: github.com/beefproject/beef"

# Create service account to run BeEF
RUN groupadd -g 1000 beef && \
    useradd -r -u 1000 -g 1000 --create-home --home-dir /beef beef

COPY . /beef

# Use gemset created by the builder above
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Grant beef service account owner and groups rights over our BeEF working directory.
RUN chown -R beef:beef /beef

# Install BeEF's runtime dependencies
RUN apt-get update && \
    apt-get install -y curl git build-essential openssl libreadline6-dev zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev autoconf libc6-dev libncurses5-dev automake libtool bison nodejs libcurl4-openssl-dev gcc-8-base libgcc-8-dev

WORKDIR /beef

# Ensure we are using our service account by default
USER beef

# Expose UI, Proxy, WebSocket server, and WebSocketSecure server
EXPOSE 3000 6789 61985 61986

ENTRYPOINT ["/beef/beef"]
# ------------------------------------- End of Builder 1 -------------------------------------------------
