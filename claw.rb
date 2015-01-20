require 'sinatra'
require 'gabba'

EDGE_LINK = 'http://go-cli.s3.amazonaws.com/master/%{file_name}'
EDGE_ARCH_TO_FILENAMES = {
    'linux32' => 'cf-linux-386.tgz',
    'linux64' => 'cf-linux-amd64.tgz',
    'macosx64' => 'cf-darwin-amd64.tgz',
    'windows32' => 'cf-windows-386.zip',
    'windows64' => 'cf-windows-amd64.zip',
}

AVAILABLE_VERSIONS = %w{
  6.0.2
  6.1.0
  6.1.1
  6.1.2
  6.2.0
  6.3.0
  6.3.1
  6.3.2
  6.4.0
  6.5.0
  6.5.1
  6.6.0
  6.6.1
  6.6.2
  6.7.0
  6.8.0
  6.9.0
}
STABLE_VERSION = AVAILABLE_VERSIONS.last
VERSIONED_RELEASE_LINK = 'http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v%{version}/%{release}'
RELEASE_TO_FILENAME = {
    'debian32' => 'cf-cli_i386.deb',
    'debian64' => 'cf-cli_amd64.deb',
    'redhat32' => 'cf-cli_i386.rpm',
    'redhat64' => 'cf-cli_amd64.rpm',
    'macosx64' => 'installer-osx-amd64.pkg',
    'windows32' => 'installer-windows-386.zip',
    'windows64' => 'installer-windows-amd64.zip',
    'linux32-binary' => 'cf-linux-386.tgz',
    'linux64-binary' => 'cf-linux-amd64.tgz',
    'macosx64-binary' => 'cf-darwin-amd64.tgz',
    'windows32-exe' => 'cf-windows-386.zip',
    'windows64-exe' => 'cf-windows-amd64.zip',
}

unless ENV.has_key?('GA_TRACKING_ID') && ENV.has_key?('GA_DOMAIN')
  puts "Expected a Google Analytics env vars but they were not set"
  exit 1
end

class Claw < Sinatra::Base
  before do
    @google_analytics = Gabba::Gabba.new(ENV['GA_TRACKING_ID'], ENV['GA_DOMAIN'], request.user_agent)
    @google_analytics.utmul = get_language
    @google_analytics.set_custom_var(1, 'ip', request.ip, 3)
    @google_analytics.set_custom_var(2, 'source', params['source'], 3)
    @google_analytics.set_custom_var(3, 'referer', request.referer, 3)
  end

  get '/ping' do
    'pong'
  end

  get '/edge' do
    if !params.has_key?('arch') || EDGE_ARCH_TO_FILENAMES[params['arch']].nil?
      halt 412, "Invalid 'arch' value, please select one of the following edge: #{EDGE_ARCH_TO_FILENAMES.keys.join(', ')}"
    end

    @google_analytics.page_view('edge', "edge/#{params['arch']}")
    redirect EDGE_LINK % {file_name: EDGE_ARCH_TO_FILENAMES[params['arch']]}, 302
  end

  get '/stable' do
    validate_stable_link_parameters(params['release'], params['version'])
    request_version = params['version'] || STABLE_VERSION

    @google_analytics.page_view('stable', "stable/#{params['release']}/#{request_version}")
    redirect VERSIONED_RELEASE_LINK % {version: request_version, release: RELEASE_TO_FILENAME[params['release']]}, 302
  end

  def validate_stable_link_parameters(release, version)
    if release.nil? || RELEASE_TO_FILENAME[release].nil?
      halt 412, "Invalid 'release' value, please select one of the following releases: #{RELEASE_TO_FILENAME.keys.join(', ')}"
    end

    if version && !AVAILABLE_VERSIONS.include?(version)
      halt 412, "Invalid 'version' value, please select one of the following versions: #{AVAILABLE_VERSIONS.join(', ')}"
    end
  end

  def get_language
    lang = request.env['HTTP_ACCEPT_LANGUAGE']
    return nil unless lang

    first_lang = lang[/\w\w-\w\w/]
    language, territory = first_lang.split('-')
    return "#{language.downcase}-#{territory.upcase}"
  end

  run! if app_file == $0
end
