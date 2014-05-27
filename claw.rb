require 'sinatra'

EDGE_LINK = 'http://go-cli.s3.amazonaws.com/master/%{file_name}'
EDGE_ARCH_TO_FILENAMES = {
    'linux32' => 'cf-linux-386.tgz',
    'linux64' => 'cf-linux-amd64.tgz',
    'macosx64' => 'cf-darwin-amd64.tgz',
    'windows32' => 'cf-windows-amd32.zip',
    'windows64' => 'cf-windows-amd64.zip',
}

LATEST_STABLE_VERSION = '6.1.2'
STABLE_LINK = 'http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v%{version}/%{release}'
STABLE_RELEASE_TO_FILENAME = {
    'debian32' => 'cf-cli_i386.deb',
    'debian64' => 'cf-cli_amd64.deb',
    'redhat32' => 'cf-cli_i386.rpm',
    'redhat64' => 'cf-cli_amd64.rpm',
    'macosx64' => 'installer-osx-amd64.pkg',
    'windows32' => 'installer-windows-386.zip',
    'windows64' => 'installer-windows-amd64.zip',
}

class Claw < Sinatra::Base
  get '/ping' do
    'pong'
  end

  get '/edge' do
    if !params.has_key?('arch') || EDGE_ARCH_TO_FILENAMES[params['arch']].nil?
      halt 412, "Invalid 'arch' value, please select one of the following edge: #{EDGE_ARCH_TO_FILENAMES.keys.join(', ')}"
    end
    redirect EDGE_LINK % {file_name: EDGE_ARCH_TO_FILENAMES[params['arch']]}, 302
  end

  get '/stable' do
    if !params.has_key?('release') || STABLE_RELEASE_TO_FILENAME[params['release']].nil?
      halt 412, "Invalid 'release' value, please select one of the following edge: #{STABLE_RELEASE_TO_FILENAME.keys.join(', ')}"
    end
    redirect STABLE_LINK % {version: LATEST_STABLE_VERSION, release: STABLE_RELEASE_TO_FILENAME[params['release']]}, 302
  end

  run! if app_file == $0
end
