require 'sinatra'
require 'gabba'

EDGE_LINK = 'http://go-cli.s3.amazonaws.com/master/%{file_name}'
EDGE_ARCH_TO_FILENAMES = {
    'linux32' => 'cf-linux-386.tgz',
    'linux64' => 'cf-linux-amd64.tgz',
    'macosx64' => 'cf-darwin-amd64.tgz',
    'windows32' => 'cf-windows-amd32.zip',
    'windows64' => 'cf-windows-amd64.zip',
}

STABLE_VERSIONS = %w{
  6.0.2
  6.1.0
  6.1.1
  6.1.2
}
LATEST_STABLE_VERSION = STABLE_VERSIONS.last
STABLE_LINK = 'http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v%{version}/%{release}'
STABLE_RELEASE_TO_FILENAME = {
    'debian32' => 'cf-cli_i386.deb',
    'debian64' => 'cf-cli_amd64.deb',
    'redhat32' => 'cf-cli_i386.rpm',
    'redhat64' => 'cf-cli_amd64.rpm',
    'macosx64' => 'installer-osx-amd64.pkg',
    'macosx64-binary' => 'cf-darwin-amd64.tgz',
    'windows32' => 'installer-windows-386.zip',
    'windows64' => 'installer-windows-amd64.zip',
}

unless ENV.has_key?('GA_TRACKING_ID') && ENV.has_key?('GA_DOMAIN')
  puts "Expected a Google Analytics env vars but they were not set"
  exit 1
end

class Claw < Sinatra::Base
  def initialize(*args)
    super
    @hey = Gabba::Gabba.new(ENV['GA_TRACKING_ID'], ENV['GA_DOMAIN'])
  end

  get '/ping' do
    'pong'
  end

  get '/edge' do
    if !params.has_key?('arch') || EDGE_ARCH_TO_FILENAMES[params['arch']].nil?
      halt 412, "Invalid 'arch' value, please select one of the following edge: #{EDGE_ARCH_TO_FILENAMES.keys.join(', ')}"
    end

    @hey.page_view('edge', "edge/#{params['arch']}")
    redirect EDGE_LINK % {file_name: EDGE_ARCH_TO_FILENAMES[params['arch']]}, 302
  end

  get '/stable' do
    validate_stable_link_parameters(params['release'], params['version'])
    request_version = params['version'] || LATEST_STABLE_VERSION

    @hey.page_view('stable', "stable/#{params['release']}", request_version)
    redirect STABLE_LINK % {version: request_version, release: STABLE_RELEASE_TO_FILENAME[params['release']]}, 302
  end

  def validate_stable_link_parameters(release, version)
    if release.nil? || STABLE_RELEASE_TO_FILENAME[release].nil?
      halt 412, "Invalid 'release' value, please select one of the following releases: #{STABLE_RELEASE_TO_FILENAME.keys.join(', ')}"
    end

    if version && !STABLE_VERSIONS.include?(version)
      halt 412, "Invalid 'version' value, please select one of the following versions: #{STABLE_VERSIONS.join(', ')}"
    end
  end

  run! if app_file == $0
end
