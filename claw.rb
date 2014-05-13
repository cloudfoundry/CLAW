require 'sinatra'

EDGE = {
  'linux32' => 'http://go-cli.s3.amazonaws.com/master/cf-linux-386.tgz',
  'linux64' => 'http://go-cli.s3.amazonaws.com/master/cf-linux-amd64.tgz',
  'macosx64' => 'http://go-cli.s3.amazonaws.com/master/cf-darwin-amd64.tgz',
  'windows32' => 'http://go-cli.s3.amazonaws.com/master/cf-windows-amd32.zip',
  'windows64' => 'http://go-cli.s3.amazonaws.com/master/cf-windows-amd64.zip',
}

STABLE = {
  'debian32' => 'http://go-cli.s3-website-us-east-1.amazonaws.com/releases/latest/cf-cli_i386.deb',
  'debian64' => 'http://go-cli.s3-website-us-east-1.amazonaws.com/releases/latest/cf-cli_amd64.deb',
  'redhat32' => 'http://go-cli.s3-website-us-east-1.amazonaws.com/releases/latest/cf-cli_i386.rpm',
  'redhat64' => 'http://go-cli.s3-website-us-east-1.amazonaws.com/releases/latest/cf-cli_amd64.rpm',
  'macosx64' => 'http://go-cli.s3-website-us-east-1.amazonaws.com/releases/latest/installer-osx-amd64.pkg',
  'windows32' => 'http://go-cli.s3-website-us-east-1.amazonaws.com/releases/latest/installer-windows-386.zip',
  'windows64' => 'http://go-cli.s3-website-us-east-1.amazonaws.com/releases/latest/installer-windows-amd64.zip',
}

class Claw < Sinatra::Base
  get '/hi' do
    "Hello World!"
  end

  get '/edge' do
    if !params.has_key?('arch') || EDGE[params['arch']].nil?
      halt 412, "Invalid 'arch' value, please select one of the following edge: #{EDGE.keys.join(', ')}"
    end
    redirect EDGE[params['arch']], 302
  end

  get '/stable' do
    if !params.has_key?('release') || STABLE[params['release']].nil?
      halt 412, "Invalid 'release' value, please select one of the following edge: #{STABLE.keys.join(', ')}"
    end
    redirect STABLE[params['release']], 302
  end

  run! if app_file == $0
end
