# CLAW
*The [CF CLI](https://github.com/cloudfoundry/cli) download redirection web application.*

![the-claw](https://2.bp.blogspot.com/-9-Mn5MRztpY/UgOgGPdOlnI/AAAAAAAACUE/Y7-oNBKjE4Y/s1600/claw.jpg)

## Why does this application exist?
* Provide a consistent link to our downloads regardless of underlying storage (be it S3, Github, etc.)
* Provide a consistent link that points the latest version of the CF CLI on a per architecture basis.
  * Amazon S3 supports a 'latest' version link, but did this via `301 Moved Permanently`. Meaning the browser would cache the old version of the link, if we recently released, for the length of the browser cache.
  * Github does not seem to be able to provide a link to the latest binary/installer on a *per architecture basis*.
* Provides analytics for each download link.

## Testing CLAW
* Run `ci/scripts/run-test.sh` in order to locally test CLAW

## Deploying Dev-CLAW
* Run `ci/bin/reconfigure-dev-pipelines.sh` to fly Dev-CLAW

## Branching strategy
All changes should be first pushed to the develop branch, and then the master branch. There is a seperate dev pipeline that works the same but pushes to a different route (cli-dev.run.pivotal.io instead of cli.run.pivotal.io and packages-dev.cloudfoundry.org instead of packages.cloudfoundry.org) Pushing to the master branch will currently automatically trigger a push to production CLAW.

## Testing Debian Dev-Claw
```
wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | sudo apt-key add -
echo "deb https://cli-dev.run.pivotal.io/debian stable main" | sudo tee /etc/apt/sources.list.d/cloudfoundry-cli.list
sudo apt-get update
sudo apt-get install cf-cli
```

## Testing RPM Dev-Claw
```
sudo wget -O /etc/yum.repos.d/cloudfoundry-cli.repo https://cli-dev.run.pivotal.io/fedora/cloudfoundry-cli.repo
sudo yum install cf7-cli
```
