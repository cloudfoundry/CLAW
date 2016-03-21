#!/bin/sh

curl -L "https://cli.run.pivotal.io/stable?release=linux64-binary&source=github-rel" > cf.tgz
tar -xzf cf.tgz

cd claw
../cf push -f manifest.yml
