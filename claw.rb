require 'sinatra'
require 'gabba'

EDGE_LINK = 'https://cf-cli-releases.s3.amazonaws.com/master/%{file_name}'
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

AVAILABLE_VERSIONS =ENV['AVAILABLE_VERSIONS'].split(",")
STABLE_VERSION = AVAILABLE_VERSIONS.last
VERSIONED_RELEASE_LINK = 'https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v%{version}/%{release}'
APT_REPO = 'https://cf-cli-debian-repo.s3.amazonaws.com/'
RPM_REPO = 'https://cf-cli-rpm-repo.s3.amazonaws.com/'

unless ENV.has_key?('GA_TRACKING_ID') && ENV.has_key?('GA_DOMAIN')
  puts "Expected a Google Analytics env vars but they were not set"
  exit 1
end

unless ENV.has_key?('GPG_KEY')
  puts "Expected a GPG_KEY env var but it was not set"
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
    @google_analytics.set_custom_var(4, 'host', request.host, 3)
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

  get /\/(debian|fedora)\/cli\.cloudfoundry\.org\.key/ do
    content_type :text
    ENV['GPG_KEY']
  end

  get '/stable' do
    version = params['version'] || STABLE_VERSION
    release = params['release']
    validate_stable_link_parameters(release, version)

    @google_analytics.page_view('stable', "stable/#{params['release']}/#{version}")
    redirect VERSIONED_RELEASE_LINK % {version: version, release: release_to_filename(release, version)}, 302
  end

  get '/debian/dists/*' do
    page = File.join('dists', params['splat'].first)
    @google_analytics.page_view('debian', page)
    redirect File.join(APT_REPO, page), 302
  end

  get '/fedora/cloudfoundry-cli.repo' do
    @google_analytics.page_view('fedora', 'cloudfoundry-cli.repo')
    redirect File.join(RPM_REPO, 'cloudfoundry-cli.repo'), 302
  end

  get '/fedora/repodata/*' do
    page = File.join('repodata', params['splat'].first)
    @google_analytics.page_view('fedora', page)
    redirect File.join(RPM_REPO, page), 302
  end

  get '/debian/pool/*' do
    page = File.join('pool', params['splat'].first)
    @google_analytics.page_view('debian', page)

    filename = page.split('/').last
    has_version = /.*_(?<version>.*)_.*/.match(filename)
    if !has_version.nil?
      version=has_version.captures.first
    redirect VERSIONED_RELEASE_LINK % {version: version, release: filename}, 302
    else
      version=STABLE_VERSION
      release=filename.split('=').last
    redirect VERSIONED_RELEASE_LINK % {version: version, release: release_to_filename(release,version)}, 302
    end
  end

  get '/fedora/releases/*' do
    page = File.join('releases', params['splat'].first)
    @google_analytics.page_view('fedora', page)

    filename = page.split('/').last
    has_version = /.*_(?<version>.*)_.*/.match(filename)
    version=has_version.captures.first
    redirect VERSIONED_RELEASE_LINK % {version: version, release: filename}, 302
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

  run! if app_file == $0
end
