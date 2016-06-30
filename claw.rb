require 'sinatra'
require 'gabba'

EDGE_LINK = 'https://go-cli.s3.amazonaws.com/master/%{file_name}'
EDGE_ARCH_TO_FILENAMES = {
    'linux32' => 'cf-cli_edge_linux_i686.tgz',
    'linux64' => 'cf-cli_edge_linux_x86-64.tgz',
    'macosx64' => 'cf-cli_edge_osx.tgz',
    'windows32' => 'cf-cli_edge_win32.zip',
    'windows64' => 'cf-cli_edge_winx64.zip',
}

RELEASE_NAMES = %w{
  debian32
  debian64
  redhat32
  redhat64
  macosx64
  windows32
  windows64
  linux32-binary
  linux64-binary
  macosx64-binary
  windows32-exe
  windows64-exe
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
  6.10.0
  6.11.0
  6.11.1
  6.11.2
  6.11.3
  6.12.0
  6.12.1
  6.12.2
  6.12.3
  6.12.4
  6.13.0
  6.14.0
  6.14.1
  6.15.0
  6.16.0
  6.16.1
  6.17.0
  6.17.1
  6.18.0
  6.18.1
  6.19.0
  6.20.0
}
STABLE_VERSION = AVAILABLE_VERSIONS.last
VERSIONED_RELEASE_LINK = 'https://s3.amazonaws.com/go-cli/releases/v%{version}/%{release}'

unless ENV.has_key?('GA_TRACKING_ID') && ENV.has_key?('GA_DOMAIN')
  puts "Expected a Google Analytics env vars but they were not set"
  exit 1
end

class Claw < Sinatra::Base
  before do
    @google_analytics = Gabba::Gabba.new(ENV['GA_TRACKING_ID'], ENV['GA_DOMAIN'], request.user_agent)
    accept_language = request.env['HTTP_ACCEPT_LANGUAGE']
    if accept_language
      @google_analytics.utmul = accept_language
    end
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
    version = params['version'] || STABLE_VERSION
    release = params['release']
    validate_stable_link_parameters(release, version)

    @google_analytics.page_view('stable', "stable/#{params['release']}/#{version}")
    redirect VERSIONED_RELEASE_LINK % {version: version, release: release_to_filename(release, version)}, 302
  end

  def validate_stable_link_parameters(release, version)
    if !RELEASE_NAMES.include?(release)
      halt 412, "Invalid 'release' value, please select one of the following releases: #{RELEASE_NAMES.join(', ')}"
    end

    if !AVAILABLE_VERSIONS.include?(version)
      halt 412, "Invalid 'version' value, please select one of the following versions: #{AVAILABLE_VERSIONS.join(', ')}"
    end
  end

  def release_to_filename(release, version)
    {
      'debian32' => "cf-cli-installer_#{version}_i686.deb",
      'debian64' => "cf-cli-installer_#{version}_x86-64.deb",
      'redhat32' => "cf-cli-installer_#{version}_i686.rpm",
      'redhat64' => "cf-cli-installer_#{version}_x86-64.rpm",
      'macosx64' => "cf-cli-installer_#{version}_osx.pkg",
      'windows32' => "cf-cli-installer_#{version}_win32.zip",
      'windows64' => "cf-cli-installer_#{version}_winx64.zip",
      'linux32-binary' => "cf-cli_#{version}_linux_i686.tgz",
      'linux64-binary' => "cf-cli_#{version}_linux_x86-64.tgz",
      'macosx64-binary' => "cf-cli_#{version}_osx.tgz",
      'windows32-exe' => "cf-cli_#{version}_win32.zip",
      'windows64-exe' => "cf-cli_#{version}_winx64.zip",
    }[release]
  end

  run! if app_file == $0 end
