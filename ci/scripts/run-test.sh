#!/bin/sh

cd claw

bundle install
bundle exec ruby claw_test.rb
