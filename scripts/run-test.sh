#!/bin/sh

# needed to build kgio
apt-get update
apt-get install build-essential -y

cd claw

gem install bundler:2.1.4

bundle install
bundle exec rake
