#!/bin/sh

curl -L "https://cli.run.pivotal.io/stable?release=linux64-binary&source=github-rel" > cf.tgz
tar -xzf cf.tgz

cd claw
../cf login -a $PWS_API -u $PWS_USERNAME -p $PWS_PASSWORD -o $PWS_ORG -s $PWS_SPACE
../cf push -f manifest.yml
