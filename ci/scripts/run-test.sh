#!/bin/sh

# needed to build kgio
apt-get update
apt-get install build-essential -y

cd claw

bundle install
bundle exec rake
