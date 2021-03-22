
FROM mcr.microsoft.com/vscode/devcontainers/universal:1-linux

USER root

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends ruby

USER codespace

RUN bundle install
